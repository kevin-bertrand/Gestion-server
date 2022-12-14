//
//  ClientController.swift
//  
//
//  Created by Kevin Bertrand on 26/08/2022.
//

import Fluent
import Vapor

struct ClientController: RouteCollection {
    // MARK: Properties
    var addressController: AddressController
    
    // MARK: Route initialisation
    func boot(routes: RoutesBuilder) throws {
        let clientGroup = routes.grouped("client")
        
        let tokenGroup = clientGroup.grouped(UserToken.authenticator()).grouped(UserToken.guardMiddleware())
        tokenGroup.post(use: create)
        tokenGroup.patch(":id", use: update)
        tokenGroup.get(use: getList)
    }
    
    // MARK: Routes functions
    /// Create client
    private func create(req: Request) async throws -> Response {
        let userAuth = try GlobalFunctions.shared.getUserAuthFor(req)
        let newClient = try req.content.decode(Client.Informations.self)
        
        guard userAuth.permissions == .admin else {
            throw Abort(.unauthorized)
        }
        
        try await Client(firstname: newClient.firstname == "" ? nil : newClient.firstname,
                         lastname: newClient.lastname == "" ? nil : newClient.lastname,
                         company: newClient.company == "" ? nil : newClient.company,
                         phone: newClient.phone,
                         email: newClient.email,
                         personType: newClient.personType,
                         gender: newClient.gender,
                         siret: newClient.siret == "" ? nil : newClient.siret,
                         tva: newClient.tva == "" ? nil : newClient.tva,
                         addressID: try await addressController.create(newClient.address, for: req).requireID())
        .save(on: req.db)
        
        return GlobalFunctions.shared.formatResponse(status: .created, body: .empty)
    }
    
    /// Update client
    private func update(req: Request) async throws -> Response {
        let userAuth = try GlobalFunctions.shared.getUserAuthFor(req)
        let updatedClient = try req.content.decode(Client.Informations.self)
        let clientId = req.parameters.get("id", as: UUID.self)
        
        guard userAuth.permissions == .admin else {
            throw Abort(.unauthorized)
        }
        
        guard let clientId = clientId else {
            throw Abort(.notAcceptable)
        }
        
        try await Client.query(on: req.db)
            .set(\.$firstname, to: updatedClient.firstname == "" ? nil : updatedClient.firstname)
            .set(\.$lastname, to: updatedClient.lastname == "" ? nil : updatedClient.lastname)
            .set(\.$company, to: updatedClient.company == "" ? nil : updatedClient.company)
            .set(\.$phone, to: updatedClient.phone)
            .set(\.$email, to: updatedClient.email)
            .set(\.$personType, to: updatedClient.personType)
            .set(\.$gender, to: updatedClient.gender ?? .notDetermined)
            .set(\.$siret, to: updatedClient.siret == "" ? nil : updatedClient.siret)
            .set(\.$tva, to: updatedClient.tva == "" ? nil : updatedClient.tva)
            .set(\.$address.$id, to: try await addressController.create(updatedClient.address, for: req).requireID())
            .filter(\.$id == clientId)
            .update()
        
        return GlobalFunctions.shared.formatResponse(status: .ok, body: .empty)
    }
    
    /// Get client list
    private func getList(req: Request) async throws -> Response {
        let clients = try await Client.query(on: req.db)
            .all()
        var processedClients: [Client.Informations] = []
        
        for client in clients {
            processedClients.append(Client.Informations(id: client.id,
                                                        firstname: client.firstname,
                                                        lastname: client.lastname,
                                                        company: client.company,
                                                        phone: client.phone,
                                                        email: client.email,
                                                        personType: client.personType,
                                                        gender: client.gender,
                                                        siret: client.siret,
                                                        tva: client.tva,
                                                        address: try await addressController.getAddressFromId(client.$address.id, for: req)))
        }
        
        return GlobalFunctions.shared.formatResponse(status: .ok, body: .init(data: try JSONEncoder().encode(processedClients)))
    }
}

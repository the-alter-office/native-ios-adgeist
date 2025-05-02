//
//  CreativeDataModel.swift
//  AdgeistKit
//
//  Created by kishore on 02/05/25.
//

import Foundation

public struct CreativeDataModel: Codable {
    public let success: Bool
    public let message: String
    public let data: Campaign?
    
    public init(success: Bool, message: String, data: Campaign?) {
        self.success = success
        self.message = message
        self.data = data
    }
}

public struct Campaign: Codable {
    public let id: String?
    public let name: String?
    public let creative: Creative?
    public let budgetSettings: BudgetSettings?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name
        case creative
        case budgetSettings
    }
    
    public init(id: String?, name: String?, creative: Creative?, budgetSettings: BudgetSettings?) {
        self.id = id
        self.name = name
        self.creative = creative
        self.budgetSettings = budgetSettings
    }
}

public struct Creative: Codable {
    public let title: String?
    public let description: String?
    public let fileUrl: String?
    public let ctaUrl: String?
    public let type: String?
    public let fileName: String?
    public let createdAt: String?
    public let updatedAt: String?
    
    public init(title: String?,
               description: String?,
               fileUrl: String?,
               ctaUrl: String?,
               type: String?,
               fileName: String?,
               createdAt: String?,
               updatedAt: String?) {
        self.title = title
        self.description = description
        self.fileUrl = fileUrl
        self.ctaUrl = ctaUrl
        self.type = type
        self.fileName = fileName
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public struct BudgetSettings: Codable {
    public let totalBudget: Double
    public let spentBudget: Double
    
    public init(totalBudget: Double, spentBudget: Double) {
        self.totalBudget = totalBudget
        self.spentBudget = spentBudget
    }
}

//
//  StorageClient.swift
//  GoogleCloudProvider
//
//  Created by Andrew Edwards on 4/16/18.
//

import Vapor

public struct GoogleCloudStorageClient: ServiceType {
    public var bucketAccessControl: GoogleBucketAccessControlAPI
    public var buckets: GoogleStorageBucketAPI
    public var channels: GoogleChannelsAPI
    public var defaultObjectAccessControl: GoogleDefaultObjectACLAPI
    public var objectAccessControl: GoogleObjectAccessControlsAPI
    public var notifications: GoogleStorageNotificationsAPI
    public var object: GoogleStorageObjectAPI
    
    init(providerconfig: GoogleCloudProviderConfig, client: Client) throws {
        let refreshableToken: OAuthRefreshable

        // Locate the ceredentials to use for this client. In order of priority:
        // - Environment Variable Specified Credentials (GOOGLE_APPLICATION_CREDENTIALS)
        // - GoogleCloudProviderConfig's serviceAccountCredentialPath (optionally configured)
        // - Application Default Credentials, located in the constant
        if let credentialPath = ProcessInfo.processInfo.environment["GOOGLE_APPLICATION_CREDENTIALS"] {
            let credentials = try GoogleServiceAccountCredentials(contentsOfFile: credentialPath)

            refreshableToken = OAuthServiceAccount(credentials: credentials, scopes: [StorageScope.fullControl], httpClient: client)
        } else if let credentialPath = providerconfig.serviceAccountCredentialPath {
            let credentials = try GoogleServiceAccountCredentials(contentsOfFile: credentialPath)

            refreshableToken = OAuthServiceAccount(credentials: credentials, scopes: [StorageScope.fullControl], httpClient: client)
        } else {
            let adcPath = NSString(string: "~/.config/gcloud/application_default_credentials.json").expandingTildeInPath
            let credentials = try GoogleApplicationDefaultCredentials(contentsOfFile: adcPath)
            refreshableToken = OAuthApplicationDefault(credentials: credentials, httpClient: client)
        }
        
        let storageRequest = GoogleCloudStorageRequest(httpClient: client, oauth: refreshableToken, project: providerconfig.project)
        
        bucketAccessControl = GoogleBucketAccessControlAPI(request: storageRequest)
        buckets = GoogleStorageBucketAPI(request: storageRequest)
        channels = GoogleChannelsAPI(request: storageRequest)
        defaultObjectAccessControl = GoogleDefaultObjectACLAPI(request: storageRequest)
        objectAccessControl = GoogleObjectAccessControlsAPI(request: storageRequest)
        notifications = GoogleStorageNotificationsAPI(request: storageRequest)
        object = GoogleStorageObjectAPI(request: storageRequest)
    }
    
    public static func makeService(for worker: Container) throws -> GoogleCloudStorageClient {
        let client = try worker.make(Client.self)
        let providerConfig = try worker.make(GoogleCloudProviderConfig.self)
        
        return try GoogleCloudStorageClient(providerconfig: providerConfig, client: client)
    }
}

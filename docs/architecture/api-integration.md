# **API Integration**

## **Service Template**

All external interactions (shell commands, network calls) will be wrapped in services that conform to a protocol.

import Foundation

// Protocol defines the contract for the service.  
protocol GitServiceProtocol {  
    func clone(repoURL: URL, to localPath: URL) async \-\> Result\<String, Error\>  
}

// Concrete implementation handles the actual logic.  
struct GitService: GitServiceProtocol {  
    func clone(repoURL: URL, to localPath: URL) async \-\> Result\<String, Error\> {  
        // Use async/await to run shell command.  
        // Return a Result type to handle success or failure.  
        return .success("Cloned successfully.")  
    }  
}

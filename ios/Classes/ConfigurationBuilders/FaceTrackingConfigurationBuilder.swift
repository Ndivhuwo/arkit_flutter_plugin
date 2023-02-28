import Foundation
import ARKit

#if !DISABLE_TRUEDEPTH_API
func createFaceTrackingConfiguration(_ arguments: Dictionary<String, Any>) -> ARFaceTrackingConfiguration? {
    if(ARFaceTrackingConfiguration.isSupported) {
        let configuration = ARFaceTrackingConfiguration()
        if #available(iOS 13.0, *) {
            configuration.isWorldTrackingEnabled = true
        }
        return configuration
    }
    return nil
}
#endif

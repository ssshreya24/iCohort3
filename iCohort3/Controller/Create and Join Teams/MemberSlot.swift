import UIKit

enum MemberSlot: Equatable {
    case currentInitial(String)     // first circle
    case filled(UIImage)            // future use if you want real photos
    case addSlot                    // person.circle + plus
    case empty                      // non-tappable placeholder
}

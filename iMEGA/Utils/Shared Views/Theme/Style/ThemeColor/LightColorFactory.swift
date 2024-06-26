import Foundation
import MEGADesignToken

struct LightColorThemeFactory: ColorFactory {
    
    func textColor(_ style: MEGAColor.Text) -> UIColor {
        switch style {
        case .primary: return UIColor.isDesignTokenEnabled() ? TokenColors.Text.primary : UIColor.black000000
        case .secondary: return UIColor.isDesignTokenEnabled() ? TokenColors.Text.secondary : UIColor.gray999999
        case .tertiary: return MEGAAppColor.Gray._515151.uiColor
        case .quaternary: return MEGAAppColor.Gray._848484.uiColor
        case .warning: return UIColor.isDesignTokenEnabled() ? TokenColors.Text.primary : MEGAAppColor.Red._FF3B30.uiColor
        }
    }
    
    func backgroundColor(_ style: MEGAColor.Background) -> UIColor {
        switch style {
        case .primary: return UIColor.isDesignTokenEnabled() ? TokenColors.Background.page: UIColor.whiteFFFFFF
        case .secondary: return UIColor.isDesignTokenEnabled() ? TokenColors.Background.page: UIColor.grayC4CCCC
            
        case .warning: return UIColor.isDesignTokenEnabled() ? TokenColors.Notifications.notificationWarning : MEGAAppColor.Yellow._FFCC0003.uiColor
        case .enabled: return MEGAAppColor.Green._00A886.uiColor
        case .disabled: return MEGAAppColor.Gray._999999.uiColor
        case .highlighted: return MEGAAppColor.Green._00A88680.uiColor
            
        case .searchTextField: return MEGAAppColor.White._EFEFEF.uiColor
        case .homeTopSide: return MEGAAppColor.White._F7F7F7.uiColor
        }
    }
    
    func tintColor(_ style: MEGAColor.Tint) -> UIColor {
        switch style {
        case .primary: return UIColor.isDesignTokenEnabled() ? TokenColors.Text.primary : UIColor.gray515151
        case .secondary: return UIColor.isDesignTokenEnabled() ? TokenColors.Text.secondary : UIColor.grayC4C4C4
        }
    }
    
    func borderColor(_ style: MEGAColor.Border) -> UIColor {
        switch style {
        case .primary: return MEGAAppColor.Black._00000015.uiColor
        case .warning: return UIColor.isDesignTokenEnabled() ? TokenColors.Notifications.notificationWarning : MEGAAppColor.Yellow._FFCC00.uiColor
        }
    }
    
    func shadowColor(_ style: MEGAColor.Shadow) -> UIColor {
        switch style {
        case .primary: return MEGAAppColor.Black._000000.uiColor
        }
    }
    
    func themeButtonTextFactory(_ style: MEGAColor.ThemeButton) -> any ButtonColorFactory {
        switch style {
        case .primary:
            return LightPrimaryThemeButtonTextColorFactory()
        case .secondary:
            return LightSecondaryThemeButtonTextColorFactory()
        }
    }
    
    func themeButtonBackgroundFactory(_ style: MEGAColor.ThemeButton) -> any ButtonColorFactory {
        switch style {
        case .primary:
            return LightPrimaryThemeButtonBackgroundColorFactory()
        case .secondary:
            return LightSecondaryThemeButtonBackgroundColorFactory()
        }
    }
    
    func customViewBackgroundFactory(_ style: MEGAColor.CustomViewBackground) -> UIColor {
        switch style {
        case .warning: return backgroundColor(.warning)
        }
    }
}

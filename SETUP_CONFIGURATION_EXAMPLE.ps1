# Optional example values. ONE_CLICK_FULL_SETUP.ps1 asks for these interactively.
$Setup = @{
    FirebaseProjectId = "YOUR_NEW_FIREBASE_PROJECT_ID"
    GitHubRepository  = "https://github.com/YOUR_ACCOUNT/QR-AJN.git"
    Domain             = "qrajn.online"

    AdMobAppId         = "ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY"
    BannerAdUnitId     = "ca-app-pub-XXXXXXXXXXXXXXXX/BBBBBBBBBB"
    InterstitialAdUnitId = "ca-app-pub-XXXXXXXXXXXXXXXX/IIIIIIIIII"
    RewardedAdUnitId   = "ca-app-pub-XXXXXXXXXXXXXXXX/RRRRRRRRRR"

    PremiumMonthlyId   = "qrajn_pro_monthly"
    PremiumYearlyId    = "qrajn_pro_yearly"
    BusinessMonthlyId  = "qrajn_business_monthly"
    BusinessYearlyId   = "qrajn_business_yearly"
}

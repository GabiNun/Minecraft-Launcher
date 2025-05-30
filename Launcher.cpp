#include <iostream>
#include <string>
#include <vector>
#include <fstream>
#include <cstdlib>
#include <filesystem>
#include <algorithm>
#include <stdexcept>
#include <cstdio>
#include <stdio.h>

#define CURL_STATICLIB
#include <curl/curl.h>
#include "json.hpp"

#include "miniz.h"

#include <windows.h>
#include <thread>
#include <chrono>

namespace fs = std::filesystem;
using json = nlohmann::json;

const std::string MS_CLIENT_ID = "00000000402b5328";
const std::string MS_REDIRECT_URI = "https://login.live.com/oauth20_desktop.srf";
const std::string MS_SCOPE = "XboxLive.signin XboxLive.offline_access";
const std::string AUTH_CACHE_FILE = "auth_cache.json";

struct AuthResult {
    bool success = false;
    std::string mcAccessToken;
    std::string mcUuid;
    std::string mcUsername;
    std::string xuid;
    std::string refreshToken;
};

static size_t WriteCallback(void* contents, size_t size, size_t nmemb, void* userp) {
    ((std::string*)userp)->append((char*)contents, size * nmemb);
    return size * nmemb;
}

static size_t WriteToFileCallback(void* contents, size_t size, size_t nmemb, FILE* stream) {
    size_t written = fwrite(contents, size, nmemb, stream);
    return written;
}

std::string httpPost(CURL* curl, const std::string& url, const std::string& postData,
                    const std::vector<std::string>& headers,
                    bool verbose = false)
{
    std::string readBuffer;
    struct curl_slist* header_list = nullptr;

    if (curl) {
        for (const auto& header : headers) {
            header_list = curl_slist_append(header_list, header.c_str());
        }
        if (header_list) {
            curl_easy_setopt(curl, CURLOPT_HTTPHEADER, header_list);
        }

        curl_easy_setopt(curl, CURLOPT_URL, url.c_str());
        curl_easy_setopt(curl, CURLOPT_POSTFIELDS, postData.c_str());
        curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, WriteCallback);
        curl_easy_setopt(curl, CURLOPT_WRITEDATA, &readBuffer);
        curl_easy_setopt(curl, CURLOPT_USERAGENT, "MinimalMinecraftLauncher/1.9");
        curl_easy_setopt(curl, CURLOPT_VERBOSE, verbose ? 1L : 0L);

        curl_easy_setopt(curl, CURLOPT_SSL_VERIFYPEER, 1L);
        curl_easy_setopt(curl, CURLOPT_SSL_VERIFYHOST, 2L);
        curl_easy_setopt(curl, CURLOPT_CAINFO, "cacert.pem");


        CURLcode res = curl_easy_perform(curl);
        if (res != CURLE_OK) {

            readBuffer = "";
        }
        if (header_list) {
            curl_slist_free_all(header_list);
        }
        curl_easy_reset(curl);
    }
    return readBuffer;
}

std::string httpGet(CURL* curl, const std::string& url, const std::vector<std::string>& headers,
                   bool verbose = false)
{
    std::string readBuffer;
    struct curl_slist* header_list = nullptr;

    if (curl) {
        for (const auto& header : headers) {
            header_list = curl_slist_append(header_list, header.c_str());
        }
        if (header_list) {
            curl_easy_setopt(curl, CURLOPT_HTTPHEADER, header_list);
        }

        curl_easy_setopt(curl, CURLOPT_URL, url.c_str());
        curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, WriteCallback);
        curl_easy_setopt(curl, CURLOPT_WRITEDATA, &readBuffer);
        curl_easy_setopt(curl, CURLOPT_USERAGENT, "MinimalMinecraftLauncher/1.9");
        curl_easy_setopt(curl, CURLOPT_FOLLOWLOCATION, 1L);
        curl_easy_setopt(curl, CURLOPT_VERBOSE, verbose ? 1L : 0L);

        curl_easy_setopt(curl, CURLOPT_SSL_VERIFYPEER, 1L);
        curl_easy_setopt(curl, CURLOPT_SSL_VERIFYHOST, 2L);
        curl_easy_setopt(curl, CURLOPT_CAINFO, "cacert.pem");


        CURLcode res = curl_easy_perform(curl);
        if (res != CURLE_OK) {

            readBuffer = "";
        }
        if (header_list) {
            curl_slist_free_all(header_list);
        }
        curl_easy_reset(curl);
    }
    return readBuffer;
}


bool downloadFile(CURL* curl, const std::string& url, const fs::path& outputPath, bool isText = false)
{
    if (!curl) return false;

    curl_easy_setopt(curl, CURLOPT_URL, url.c_str());
    curl_easy_setopt(curl, CURLOPT_FOLLOWLOCATION, 1L);
    curl_easy_setopt(curl, CURLOPT_NOPROGRESS, 1L);
    curl_easy_setopt(curl, CURLOPT_USERAGENT, "MinimalMinecraftLauncher/1.9");

    curl_easy_setopt(curl, CURLOPT_SSL_VERIFYPEER, 1L);
    curl_easy_setopt(curl, CURLOPT_SSL_VERIFYHOST, 2L);
    curl_easy_setopt(curl, CURLOPT_CAINFO, "cacert.pem");


    if (isText) {
        std::string readBuffer;
        curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, WriteCallback);
        curl_easy_setopt(curl, CURLOPT_WRITEDATA, &readBuffer);
        CURLcode res = curl_easy_perform(curl);

        curl_easy_reset(curl);
        if (res == CURLE_OK) {
            std::ofstream outFile(outputPath);
            if (outFile.is_open()) {
                outFile << readBuffer;
                outFile.close();
                return true;
            } else {

            }
        } else {

        }
    } else {

        FILE* fp = fopen(outputPath.string().c_str(), "wb");
        if (fp) {

            struct FileCloser {
                FILE* file_ptr;
                ~FileCloser() { if (file_ptr) fclose(file_ptr); }
            } fileCloser{fp};

            curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, WriteToFileCallback);
            curl_easy_setopt(curl, CURLOPT_WRITEDATA, fp);
            CURLcode res = curl_easy_perform(curl);

            curl_easy_reset(curl);
            if (res != CURLE_OK) {


                 return false;
            }

            return true;
        } else {

        }
    }

     curl_easy_reset(curl);
    return false;
}

bool extractZip(const fs::path& zipPath, const fs::path& extractToDir) {
    mz_zip_archive zip_archive;
    memset(&zip_archive, 0, sizeof(zip_archive));
    if (!mz_zip_reader_init_file(&zip_archive, zipPath.string().c_str(), 0)) {

        return false;
    }
    fs::create_directories(extractToDir);
    for (mz_uint i = 0; i < mz_zip_reader_get_num_files(&zip_archive); i++) {
        mz_zip_archive_file_stat file_stat;
        if (!mz_zip_reader_file_stat(&zip_archive, i, &file_stat)) {

            continue;
        }
        fs::path outputPath = extractToDir / file_stat.m_filename;

        try {
             fs::path canonicalExtractPath = fs::weakly_canonical(outputPath);
             fs::path canonicalDestDir = fs::weakly_canonical(extractToDir);
             if (canonicalExtractPath.string().rfind(canonicalDestDir.string(), 0) != 0) {

                 continue;
             }
        } catch (const fs::filesystem_error& e) {

             continue;
        }


        if (mz_zip_reader_is_file_a_directory(&zip_archive, i)) {
            fs::create_directories(outputPath);
            continue;
        } else {
            if (outputPath.has_parent_path()) {
                fs::create_directories(outputPath.parent_path());
            }
        }
        if (!mz_zip_reader_extract_to_file(&zip_archive, i, outputPath.string().c_str(), 0)){

        }
    }
    mz_zip_reader_end(&zip_archive);
    return true;
}


AuthResult performMicrosoftLogin(CURL* curl) {
    AuthResult authRes;
    std::string authUrl = "https://login.live.com/oauth20_authorize.srf";
    authUrl += "?client_id=" + MS_CLIENT_ID;
    authUrl += "&response_type=code";

    char* escaped_redirect_uri = curl_easy_escape(curl, MS_REDIRECT_URI.c_str(), 0);
    if (escaped_redirect_uri) {
        authUrl += "&redirect_uri=";
        authUrl += escaped_redirect_uri;
        curl_free(escaped_redirect_uri);
    } else {
        std::cerr << "Failed to escape redirect URI" << std::endl;
        return authRes;
    }

    char* escaped_scope = curl_easy_escape(curl, MS_SCOPE.c_str(), 0);
    if (escaped_scope) {
        authUrl += "&scope=";
        authUrl += escaped_scope;
        curl_free(escaped_scope);
    } else {
        std::cerr << "Failed to escape scope" << std::endl;
        return authRes;
    }
    authUrl += "&prompt=select_account";

    std::cout << "Microsoft Login Required." << std::endl;
    std::cout << "Opening login page in your browser..." << std::endl;
    std::cout << "(If it doesn't open, manually visit: " << authUrl << ")" << std::endl;

    HINSTANCE result = ShellExecuteA(NULL, "open", authUrl.c_str(), NULL, NULL, SW_SHOWNORMAL);
    if ((intptr_t)result <= 32) {
         std::cerr << "Warning: Could not automatically open browser (Error code: " << (intptr_t)result << ")." << std::endl;
         std::cerr << "         Please manually open the URL printed above." << std::endl;
    }

    std::cout << "After logging in and authorizing, Microsoft will redirect you to a blank page." << std::endl;
    std::cout << "Copy the *entire* URL from your browser's address bar for that blank page." << std::endl;
    std::cout << "It will look like: '" << MS_REDIRECT_URI << "?code=M.R3_BAY.LongCodeHere'" << std::endl;
    std::cout << "Please paste the ENTIRE redirected URL here and press Enter:\n> ";
    std::string redirectedUrl;
    std::getline(std::cin, redirectedUrl);

    size_t codePos = redirectedUrl.find("?code=");
    if (codePos == std::string::npos) codePos = redirectedUrl.find("&code=");
    if (codePos == std::string::npos) {
        std::cerr << "Could not find '?code=' or '&code=' in the pasted URL." << std::endl;
        return authRes;
    }
    std::string authCode = redirectedUrl.substr(codePos + 6);
    size_t fragmentPos = authCode.find('&');
    if (fragmentPos != std::string::npos) authCode = authCode.substr(0, fragmentPos);


    std::string tokenPostData = "client_id=" + MS_CLIENT_ID;
    tokenPostData += "&code=" + authCode;
    tokenPostData += "&grant_type=authorization_code";
    tokenPostData += "&redirect_uri=" + MS_REDIRECT_URI;
    tokenPostData += "&scope=" + MS_SCOPE;

    std::string msTokenResponse = httpPost(curl, "https://login.live.com/oauth20_token.srf", tokenPostData, {"Content-Type: application/x-www-form-urlencoded"});
    if (msTokenResponse.empty()) { std::cerr << "MS token request failed." << std::endl; return authRes; }

    json msTokenJson;
    try {
        msTokenJson = json::parse(msTokenResponse);
    } catch (const json::parse_error& e) {
        std::cerr << "MS token JSON parse error: " << e.what() << "\nResponse: " << msTokenResponse << std::endl;
        return authRes;
    }

    if (!msTokenJson.contains("access_token") || !msTokenJson["access_token"].is_string()) {
        std::cerr << "MS access_token not found or not a string in response: " << msTokenResponse << std::endl;
        return authRes;
    }
    std::string msAccessToken = msTokenJson["access_token"];

    if (msTokenJson.contains("refresh_token") && msTokenJson["refresh_token"].is_string()) {
        authRes.refreshToken = msTokenJson["refresh_token"];
    } else {
         std::cerr << "Warning: Refresh token not found in Microsoft token response." << std::endl;

    }


    json xblAuthPayload = {
        {"Properties", {
            {"AuthMethod", "RPS"},
            {"SiteName", "user.auth.xboxlive.com"},
            {"RpsTicket", "d=" + msAccessToken}
        }},
        {"RelyingParty", "http://auth.xboxlive.com"},
        {"TokenType", "JWT"}
    };
    std::string xblResponse = httpPost(curl, "https://user.auth.xboxlive.com/user/authenticate", xblAuthPayload.dump(), {"Content-Type: application/json", "Accept: application/json"});
    if (xblResponse.empty()) { std::cerr << "XBL auth request failed." << std::endl; return authRes; }

    json xblJson;
    try {
        xblJson = json::parse(xblResponse);
    } catch (const json::parse_error& e) {
        std::cerr << "XBL JSON parse error: " << e.what() << "\nResponse: " << xblResponse << std::endl;
        return authRes;
    }
    if (!xblJson.contains("Token") || !xblJson["Token"].is_string() ||
        !xblJson.contains("DisplayClaims") || !xblJson["DisplayClaims"].is_object() ||
        !xblJson["DisplayClaims"].contains("xui") || !xblJson["DisplayClaims"]["xui"].is_array() ||
        xblJson["DisplayClaims"]["xui"].empty() || !xblJson["DisplayClaims"]["xui"][0].is_object() ||
        !xblJson["DisplayClaims"]["xui"][0].contains("uhs") || !xblJson["DisplayClaims"]["xui"][0]["uhs"].is_string())
    {
        std::cerr << "XBL Token/UHS not found or invalid in response: " << xblResponse << std::endl;

        return authRes;
    }
    std::string xblToken = xblJson["Token"];
    std::string userHash = xblJson["DisplayClaims"]["xui"][0]["uhs"];


    json xstsAuthPayload = {
        {"Properties", {
            {"SandboxId", "RETAIL"},
            {"UserTokens", json::array({xblToken})}
        }},
        {"RelyingParty", "rp://api.minecraftservices.com/"},
        {"TokenType", "JWT"}
    };
    std::string xstsResponse = httpPost(curl, "https://xsts.auth.xboxlive.com/xsts/authorize", xstsAuthPayload.dump(), {"Content-Type: application/json", "Accept: application/json"});
    if (xstsResponse.empty()) { std::cerr << "XSTS auth request failed." << std::endl; return authRes; }

    json xstsJson;
    try {
        xstsJson = json::parse(xstsResponse);
    } catch (const json::parse_error& e) {
        std::cerr << "XSTS JSON parse error: " << e.what() << "\nResponse: " << xstsResponse << std::endl;
        return authRes;
    }
    if (!xstsJson.contains("Token") || !xstsJson["Token"].is_string()) {
        if (xstsJson.contains("XErr")) {
            long xerr = -1;
            if (xstsJson["XErr"].is_number()) {
                 xerr = xstsJson["XErr"].get<long>();
            } else if (xstsJson["XErr"].is_string()) {
                try {
                     xerr = std::stol(xstsJson["XErr"].get<std::string>());
                } catch (const std::invalid_argument& ia) {
                    std::cerr << "XSTS Error: Could not parse XErr string value '" << xstsJson["XErr"].get<std::string>() << "'" << std::endl;
                } catch (const std::out_of_range& oor) {
                    std::cerr << "XSTS Error: XErr string value out of range '" << xstsJson["XErr"].get<std::string>() << "'" << std::endl;
                }
            }

            std::cerr << "XSTS Error: " << xerr;
            if (xstsJson.contains("Message") && xstsJson["Message"].is_string()) std::cerr << " - " << xstsJson["Message"].get<std::string>();
            std::cerr << std::endl;
            if (xerr == 2148916233L) std::cerr << "Account doesn't own Minecraft or it's not on this Microsoft Account." << std::endl;
            if (xerr == 2148916238L) std::cerr << "Child account, parental controls might be preventing login." << std::endl;
        } else {
            std::cerr << "XSTS Token not found and no XErr. Response: " << xstsResponse << std::endl;
        }
        return authRes;
    }
    std::string xstsToken = xstsJson["Token"];


    if (xstsJson.contains("DisplayClaims") && xstsJson["DisplayClaims"].is_object() &&
        xstsJson["DisplayClaims"].contains("xui") && xstsJson["DisplayClaims"]["xui"].is_array() &&
        !xstsJson["DisplayClaims"]["xui"].empty() && xstsJson["DisplayClaims"]["xui"][0].is_object() &&
        xstsJson["DisplayClaims"]["xui"][0].contains("xid") && xstsJson["DisplayClaims"]["xui"][0]["xid"].is_string())
    {
        authRes.xuid = xstsJson["DisplayClaims"]["xui"][0]["xid"].get<std::string>();
    } else {
        std::cerr << "Warning: Could not extract XUID from XSTS response." << std::endl;
        authRes.xuid = "";
    }


    json mcLoginPayload = { {"identityToken", "XBL3.0 x=" + userHash + ";" + xstsToken} };
    std::string mcLoginResponse = httpPost(curl, "https://api.minecraftservices.com/authentication/login_with_xbox", mcLoginPayload.dump(), {"Content-Type: application/json", "Accept: application/json"});
    if (mcLoginResponse.empty()) { std::cerr << "MC login request failed." << std::endl; return authRes; }

    json mcLoginJson;
    try {
        mcLoginJson = json::parse(mcLoginResponse);
    } catch (const json::parse_error& e) {
        std::cerr << "MC login JSON parse error: " << e.what() << "\nResponse: " << mcLoginResponse << std::endl;
        return authRes;
    }
    if (!mcLoginJson.contains("access_token") || !mcLoginJson["access_token"].is_string()) {
        std::cerr << "MC access_token not found or invalid in response: " << mcLoginResponse << std::endl;
        return authRes;
    }
    authRes.mcAccessToken = mcLoginJson["access_token"];

    std::string mcProfileResponse = httpGet(curl, "https://api.minecraftservices.com/minecraft/profile", {"Authorization: Bearer " + authRes.mcAccessToken});
    if (mcProfileResponse.empty()) { std::cerr << "MC profile request failed." << std::endl; return authRes; }

     json mcProfileJson;
     try {
         mcProfileJson = json::parse(mcProfileResponse);
     } catch (const json::parse_error& e) {
         std::cerr << "MC profile JSON parse error: " << e.what() << "\nResponse: " << mcProfileResponse << std::endl;
         return authRes;
     }
     if (!mcProfileJson.contains("id") || !mcProfileJson["id"].is_string() ||
         !mcProfileJson.contains("name") || !mcProfileJson["name"].is_string()) {
         std::cerr << "MC UUID/Name not found or invalid in response: " << mcProfileResponse << std::endl;
         return authRes;
     }

    authRes.mcUuid = mcProfileJson["id"];
    authRes.mcUuid.erase(std::remove(authRes.mcUuid.begin(), authRes.mcUuid.end(), '-'), authRes.mcUuid.end());
    authRes.mcUsername = mcProfileJson["name"];
    authRes.success = true;

    std::cout << "Login Succeeded! User: " << authRes.mcUsername << ", UUID: " << authRes.mcUuid << std::endl;
    return authRes;
}


void saveAuthCache(const AuthResult& auth) {
    if (!auth.success || auth.refreshToken.empty()) {
         if (fs::exists(AUTH_CACHE_FILE)) {
             try { fs::remove(AUTH_CACHE_FILE); } catch(...) {}
         }
        return;
    }
    json cacheData;
    cacheData["refreshToken"] = auth.refreshToken;
    cacheData["mcUsername"] = auth.mcUsername;
    cacheData["mcUuid"] = auth.mcUuid;

    std::ofstream o(AUTH_CACHE_FILE);
    if (o.is_open()) {
        try {
             o << cacheData.dump(4);
             o.close();
        } catch (const std::exception& e) {
            std::cerr << "Error writing auth cache: " << e.what() << std::endl;
             o.close();
             try { fs::remove(AUTH_CACHE_FILE); } catch(...) {}
        }
    } else {
        std::cerr << "Error: Could not open auth cache file for writing: " << AUTH_CACHE_FILE << std::endl;
    }
}


AuthResult loadAuthCache() {
    AuthResult cachedAuth;
    if (fs::exists(AUTH_CACHE_FILE)) {
        std::ifstream i(AUTH_CACHE_FILE);
        if (i.is_open()) {
            try {
                json cacheData;
                i >> cacheData;
                i.close();
                if (cacheData.contains("refreshToken") && cacheData["refreshToken"].is_string()) {
                    cachedAuth.refreshToken = cacheData["refreshToken"];

                    cachedAuth.mcUsername = cacheData.value("mcUsername", "");
                    cachedAuth.mcUuid = cacheData.value("mcUuid", "");
                    cachedAuth.success = !cachedAuth.refreshToken.empty();
                } else {
                     i.close();
                     std::cerr << "Auth cache file is invalid, deleting." << std::endl;
                     try { fs::remove(AUTH_CACHE_FILE); } catch(...) {}
                }
            } catch (const json::parse_error& e) {
                std::cerr << "Error parsing auth cache file: " << e.what() << std::endl;
                i.close();
                 try { fs::remove(AUTH_CACHE_FILE); } catch(...) {}
            } catch (const std::exception& e) {
                std::cerr << "Error reading auth cache file: " << e.what() << std::endl;
                 i.close();
                 try { fs::remove(AUTH_CACHE_FILE); } catch(...) {}
            }
        } else {
            std::cerr << "Could not open auth cache file for reading: " << AUTH_CACHE_FILE << std::endl;
        }
    }

    return cachedAuth;
}

AuthResult refreshMicrosoftLogin(CURL* curl, const std::string& refreshToken) {
    AuthResult authRes;
    authRes.refreshToken = refreshToken;

    std::string tokenPostData = "client_id=" + MS_CLIENT_ID;
    tokenPostData += "&refresh_token=" + refreshToken;
    tokenPostData += "&grant_type=refresh_token";
    tokenPostData += "&scope=" + MS_SCOPE;

    std::string msTokenResponse = httpPost(curl, "https://login.live.com/oauth20_token.srf", tokenPostData, {"Content-Type: application/x-www-form-urlencoded"});

    if (msTokenResponse.empty()) {
        std::cerr << "MS token refresh request failed." << std::endl;
        return authRes;
    }

    json msTokenJson;
    try {
        msTokenJson = json::parse(msTokenResponse);
    } catch (const json::parse_error& e) {
        std::cerr << "MS refresh token JSON parse error: " << e.what() << "\nResponse: " << msTokenResponse << std::endl;
        return authRes;
    }

    if (msTokenJson.contains("error")) {
         std::string error = msTokenJson.value("error", "");
         std::string error_desc = msTokenJson.value("error_description", "");
         std::cerr << "MS token refresh error: " << error << " - " << error_desc << std::endl;

         if (error == "invalid_grant") {
             std::cerr << "Refresh token is invalid or expired. Need full login." << std::endl;

             authRes.refreshToken = "";
         }
         return authRes;
    }


    if (!msTokenJson.contains("access_token") || !msTokenJson["access_token"].is_string()) {
        std::cerr << "MS access_token not found in refresh response: " << msTokenResponse << std::endl;
        return authRes;
    }
    std::string msAccessToken = msTokenJson["access_token"];


    if (msTokenJson.contains("refresh_token") && msTokenJson["refresh_token"].is_string()) {
        authRes.refreshToken = msTokenJson["refresh_token"];

    } else {


    }


    json xblAuthPayload = {
        {"Properties", {
            {"AuthMethod", "RPS"},
            {"SiteName", "user.auth.xboxlive.com"},
            {"RpsTicket", "d=" + msAccessToken}
        }},
        {"RelyingParty", "http://auth.xboxlive.com"},
        {"TokenType", "JWT"}
    };
    std::string xblResponse = httpPost(curl, "https://user.auth.xboxlive.com/user/authenticate", xblAuthPayload.dump(), {"Content-Type: application/json", "Accept: application/json"});
    if (xblResponse.empty()) { std::cerr << "XBL auth request failed (during refresh)." << std::endl; return authRes; }

    json xblJson;
    try { xblJson = json::parse(xblResponse); } catch (const json::parse_error& e) { std::cerr << "XBL JSON parse error (refresh): " << e.what() << "\nResponse: " << xblResponse << std::endl; return authRes; }
    if (!xblJson.contains("Token") || !xblJson["Token"].is_string() ||
        !xblJson.contains("DisplayClaims") || !xblJson["DisplayClaims"].is_object() ||
        !xblJson["DisplayClaims"].contains("xui") || !xblJson["DisplayClaims"]["xui"].is_array() ||
        xblJson["DisplayClaims"]["xui"].empty() || !xblJson["DisplayClaims"]["xui"][0].is_object() ||
        !xblJson["DisplayClaims"]["xui"][0].contains("uhs") || !xblJson["DisplayClaims"]["xui"][0]["uhs"].is_string())
    {
        std::cerr << "XBL Token/UHS not found or invalid (refresh): " << xblResponse << std::endl; return authRes;
    }
    std::string xblToken = xblJson["Token"];
    std::string userHash = xblJson["DisplayClaims"]["xui"][0]["uhs"];


    json xstsAuthPayload = {
        {"Properties", {
            {"SandboxId", "RETAIL"},
            {"UserTokens", json::array({xblToken})}
        }},
        {"RelyingParty", "rp://api.minecraftservices.com/"},
        {"TokenType", "JWT"}
    };
    std::string xstsResponse = httpPost(curl, "https://xsts.auth.xboxlive.com/xsts/authorize", xstsAuthPayload.dump(), {"Content-Type: application/json", "Accept: application/json"});
    if (xstsResponse.empty()) { std::cerr << "XSTS auth request failed (refresh)." << std::endl; return authRes; }

    json xstsJson;
    try { xstsJson = json::parse(xstsResponse); } catch (const json::parse_error& e) { std::cerr << "XSTS JSON parse error (refresh): " << e.what() << "\nResponse: " << xstsResponse << std::endl; return authRes; }
    if (!xstsJson.contains("Token") || !xstsJson["Token"].is_string()) {
         std::cerr << "XSTS Token not found or invalid (refresh): " << xstsResponse << std::endl;

         return authRes;
    }
    std::string xstsToken = xstsJson["Token"];

    if (xstsJson.contains("DisplayClaims") && xstsJson["DisplayClaims"].is_object() &&
        xstsJson["DisplayClaims"].contains("xui") && xstsJson["DisplayClaims"]["xui"].is_array() &&
        !xstsJson["DisplayClaims"]["xui"].empty() && xstsJson["DisplayClaims"]["xui"][0].is_object() &&
        xstsJson["DisplayClaims"]["xui"][0].contains("xid") && xstsJson["DisplayClaims"]["xui"][0]["xid"].is_string())
    {
        authRes.xuid = xstsJson["DisplayClaims"]["xui"][0]["xid"].get<std::string>();
    } else {
        std::cerr << "Warning: Could not extract XUID from XSTS response (refresh)." << std::endl;
        authRes.xuid = "";
    }


    json mcLoginPayload = { {"identityToken", "XBL3.0 x=" + userHash + ";" + xstsToken} };
    std::string mcLoginResponse = httpPost(curl, "https://api.minecraftservices.com/authentication/login_with_xbox", mcLoginPayload.dump(), {"Content-Type: application/json", "Accept: application/json"});
    if (mcLoginResponse.empty()) { std::cerr << "MC login request failed (refresh)." << std::endl; return authRes; }

    json mcLoginJson;
    try { mcLoginJson = json::parse(mcLoginResponse); } catch (const json::parse_error& e) { std::cerr << "MC login JSON parse error (refresh): " << e.what() << "\nResponse: " << mcLoginResponse << std::endl; return authRes; }
    if (!mcLoginJson.contains("access_token") || !mcLoginJson["access_token"].is_string()) { std::cerr << "MC access_token not found (refresh): " << mcLoginResponse << std::endl; return authRes; }
    authRes.mcAccessToken = mcLoginJson["access_token"];

    std::string mcProfileResponse = httpGet(curl, "https://api.minecraftservices.com/minecraft/profile", {"Authorization: Bearer " + authRes.mcAccessToken});
    if (mcProfileResponse.empty()) { std::cerr << "MC profile request failed (refresh)." << std::endl; return authRes; }

     json mcProfileJson;
     try { mcProfileJson = json::parse(mcProfileResponse); } catch (const json::parse_error& e) { std::cerr << "MC profile JSON parse error (refresh): " << e.what() << "\nResponse: " << mcProfileResponse << std::endl; return authRes; }
     if (!mcProfileJson.contains("id") || !mcProfileJson["id"].is_string() ||
         !mcProfileJson.contains("name") || !mcProfileJson["name"].is_string()) {
         std::cerr << "MC UUID/Name not found (refresh): " << mcProfileResponse << std::endl; return authRes;
     }

    authRes.mcUuid = mcProfileJson["id"];
    authRes.mcUuid.erase(std::remove(authRes.mcUuid.begin(), authRes.mcUuid.end(), '-'), authRes.mcUuid.end());
    authRes.mcUsername = mcProfileJson["name"];
    authRes.success = true;


    return authRes;
}

void RedirectIOToConsole() {
    FILE* fp;

    if (freopen_s(&fp, "CONIN$", "r", stdin) != 0) {

    } else {
        setvbuf(stdin, NULL, _IONBF, 0);
    }

    if (freopen_s(&fp, "CONOUT$", "w", stdout) != 0) {
        MessageBoxA(NULL, "Failed to redirect stdout.", "Console Error", MB_OK | MB_ICONERROR);
    } else {
        setvbuf(stdout, NULL, _IONBF, 0);
    }

    if (freopen_s(&fp, "CONOUT$", "w", stderr) != 0) {
         MessageBoxA(NULL, "Failed to redirect stderr.", "Console Error", MB_OK | MB_ICONERROR);
    } else {
         setvbuf(stderr, NULL, _IONBF, 0);
    }

    std::ios::sync_with_stdio(true);
}


int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow) {


    bool console_attached = false;
    bool console_was_allocated_by_us = false;

    curl_global_init(CURL_GLOBAL_ALL);
    CURL* curl = curl_easy_init();
    if (!curl) {

        MessageBoxA(NULL, "Failed to initialize libcurl.", "Launcher Error", MB_OK | MB_ICONERROR);
        return 1;
    }

    std::string mcVersionInput = "1.21.5";
    std::string maxMemory = "2G";
    std::string minMemory = "1G";

    AuthResult authDetails;
    bool required_manual_login = false;


    AuthResult cachedAuth = loadAuthCache();

    if (cachedAuth.success) {

        authDetails = refreshMicrosoftLogin(curl, cachedAuth.refreshToken);

        if (!authDetails.success) {

             if (AttachConsole(ATTACH_PARENT_PROCESS)) {
                 console_attached = true;
                 RedirectIOToConsole();
             } else {
                 if (AllocConsole()) {
                    console_attached = true;
                    console_was_allocated_by_us = true;
                    RedirectIOToConsole();
                 } else {

                 }
             }

             std::cerr << "Token refresh failed. Initiating full login." << std::endl;
             if (authDetails.refreshToken.empty() && fs::exists(AUTH_CACHE_FILE)) {
                  try {fs::remove(AUTH_CACHE_FILE);} catch(...) {}
             }
             required_manual_login = true;
             authDetails = performMicrosoftLogin(curl);
        }

    } else {

        if (AttachConsole(ATTACH_PARENT_PROCESS)) {
             console_attached = true;
             RedirectIOToConsole();
        } else {
             if (AllocConsole()) {
                 console_attached = true;
                 console_was_allocated_by_us = true;
                 RedirectIOToConsole();
             } else {

             }
        }

        std::cout << "No valid cached token found. Initiating full login." << std::endl;
        required_manual_login = true;
        authDetails = performMicrosoftLogin(curl);
    }


    if (!authDetails.success) {

        std::string errorMsg = "Authentication failed. Cannot continue.";
         if (console_attached) {
             std::cerr << errorMsg << std::endl;
         } else {
             MessageBoxA(NULL, errorMsg.c_str(), "Launcher Error", MB_OK | MB_ICONERROR);
         }
        curl_easy_cleanup(curl);
        curl_global_cleanup();
        if (console_was_allocated_by_us) FreeConsole();
        return 1;
    }


    saveAuthCache(authDetails);

    if (console_was_allocated_by_us) {
         FreeConsole();
         console_attached = false;
         console_was_allocated_by_us = false;
    }


    fs::path gameDir = ".";
    fs::path versionsDir = gameDir / "versions";
    fs::path versionDir = versionsDir / mcVersionInput;
    fs::path nativesDir = versionDir / (mcVersionInput + "-natives");
    fs::path librariesDir = gameDir / "libraries";
    fs::path assetsDir = gameDir / "assets";
    fs::path assetIndexesDir = assetsDir / "indexes";
    fs::path assetObjectsDir = assetsDir / "objects";

    try {
        fs::create_directories(versionDir);
        fs::create_directories(nativesDir);
        fs::create_directories(librariesDir);
        fs::create_directories(assetIndexesDir);
        fs::create_directories(assetObjectsDir);
    } catch (const fs::filesystem_error& e) {
         std::string errorMsg = "Error creating directories: "; errorMsg += e.what();
          if (console_attached) std::cerr << errorMsg << std::endl; else MessageBoxA(NULL, errorMsg.c_str(), "Launcher Error", MB_OK | MB_ICONERROR);

    }


    std::string versionManifestUrl = "https://launchermeta.mojang.com/mc/game/version_manifest_v2.json";
    fs::path versionManifestPath = gameDir / "version_manifest_v2.json";
    std::string specificVersionUrl;

    if (!fs::exists(versionManifestPath)) {

        if(!downloadFile(curl, versionManifestUrl, versionManifestPath, true)){
             std::string errorMsg = "Initial download of version_manifest_v2.json failed. Cannot continue.";
             if (console_attached) std::cerr << errorMsg << std::endl; else MessageBoxA(NULL, errorMsg.c_str(), "Launcher Error", MB_OK | MB_ICONERROR);
             curl_easy_cleanup(curl); curl_global_cleanup(); if (console_attached) FreeConsole(); return 1;
        }
    }

    json versionManifest;

    if(fs::exists(versionManifestPath)){
        std::ifstream vmf(versionManifestPath);
        if (!vmf.is_open()) {
             if (console_attached) std::cerr << "Error opening cached manifest file: " << versionManifestPath << std::endl;

        } else {
            try {
                vmf >> versionManifest;
                vmf.close();
            } catch (const json::parse_error& e) {
                if (console_attached) std::cerr << "Error parsing cached manifest: " << e.what() << std::endl;
                vmf.close();
                versionManifest = nullptr;
            }
        }
    }


    if(versionManifest.is_null() || !versionManifest.contains("versions")) {

        if(downloadFile(curl, versionManifestUrl, versionManifestPath, true)) {
            std::ifstream vmf_retry(versionManifestPath);
            if (vmf_retry.is_open()) {
                 try {
                     vmf_retry >> versionManifest;
                     vmf_retry.close();
                 } catch (const json::parse_error& e) {
                     if (console_attached) std::cerr << "Error parsing re-downloaded manifest: " << e.what() << std::endl;
                     vmf_retry.close();
                     versionManifest = nullptr;
                 }
            } else { if (console_attached) std::cerr << "Failed to open re-downloaded manifest." << std::endl; versionManifest = nullptr; }
        } else {
            std::string errorMsg = "Failed to download version manifest on retry. Cannot continue.";
             if (console_attached) std::cerr << errorMsg << std::endl; else MessageBoxA(NULL, errorMsg.c_str(), "Launcher Error", MB_OK | MB_ICONERROR);
             curl_easy_cleanup(curl); curl_global_cleanup(); if (console_attached) FreeConsole(); return 1;
        }
    }


    if (versionManifest.is_null() || !versionManifest.contains("versions") || !versionManifest["versions"].is_array()) {
         std::string errorMsg = "Invalid or missing version manifest. Cannot continue.";
         if (console_attached) std::cerr << errorMsg << std::endl; else MessageBoxA(NULL, errorMsg.c_str(), "Launcher Error", MB_OK | MB_ICONERROR);
         curl_easy_cleanup(curl); curl_global_cleanup(); if (console_attached) FreeConsole(); return 1;
    }


    if (versionManifest.contains("versions") && versionManifest["versions"].is_array()) {
        for (const auto& version : versionManifest["versions"]) {
            if (version.is_object() && version.contains("id") && version["id"] == mcVersionInput) {
                if (version.contains("url")) specificVersionUrl = version["url"];
                break;
            }
        }
    }


    if (specificVersionUrl.empty()) {
         std::string errorMsg = "Could not find version '" + mcVersionInput + "' url in manifest.";
         if (console_attached) std::cerr << errorMsg << std::endl; else MessageBoxA(NULL, errorMsg.c_str(), "Launcher Error", MB_OK | MB_ICONERROR);
         if(fs::exists(versionManifestPath) && console_attached) {

         }
        curl_easy_cleanup(curl); curl_global_cleanup(); if (console_attached) FreeConsole(); return 1;
    }


    fs::path mcJsonPath = versionDir / (mcVersionInput + ".json");
    json mcJson;
    if(fs::exists(mcJsonPath)){
        std::ifstream mcf(mcJsonPath);
         if (!mcf.is_open()) {
             if (console_attached) std::cerr << "Error opening cached version JSON: " << mcJsonPath << std::endl;
         } else {
             try { mcf >> mcJson; mcf.close(); } catch (const json::parse_error& e) {
                 if (console_attached) std::cerr << "Error parsing cached version JSON: " << e.what() << std::endl;
                 mcf.close(); mcJson = nullptr;
             }
         }
    }

    if(mcJson.is_null() || !mcJson.contains("id")){

        if(downloadFile(curl, specificVersionUrl, mcJsonPath, true)){
            std::ifstream mcf_retry(mcJsonPath);
            if (mcf_retry.is_open()) {
                try { mcf_retry >> mcJson; mcf_retry.close(); } catch (const json::parse_error& e) {
                    if (console_attached) std::cerr << "Error parsing downloaded version JSON: " << e.what() << std::endl;
                    mcf_retry.close(); mcJson = nullptr;
                }
            } else { if (console_attached) std::cerr << "Failed to open downloaded version JSON." << std::endl; mcJson = nullptr; }
        } else {
            std::string errorMsg = "Failed to download version JSON: " + mcJsonPath.filename().string() + ". Cannot continue.";
            if (console_attached) std::cerr << errorMsg << std::endl; else MessageBoxA(NULL, errorMsg.c_str(), "Launcher Error", MB_OK | MB_ICONERROR);
            curl_easy_cleanup(curl); curl_global_cleanup(); if (console_attached) FreeConsole(); return 1;
        }
    }

    if (mcJson.is_null() || !mcJson.contains("id")) {
         std::string errorMsg = "Failed to load/download " + mcJsonPath.filename().string() + ". Cannot continue.";
         if (console_attached) std::cerr << errorMsg << std::endl; else MessageBoxA(NULL, errorMsg.c_str(), "Launcher Error", MB_OK | MB_ICONERROR);
         curl_easy_cleanup(curl); curl_global_cleanup(); if (console_attached) FreeConsole(); return 1;
    }


    fs::path gameJar = versionDir / (mcVersionInput + ".jar");
    if (!fs::exists(gameJar)) {
        if (console_attached) std::cout << "Downloading game JAR..." << std::endl;
        if (mcJson.contains("downloads") && mcJson["downloads"].is_object() && mcJson["downloads"].contains("client") && mcJson["downloads"]["client"].is_object() && mcJson["downloads"]["client"].contains("url")) {
            if (!downloadFile(curl, mcJson["downloads"]["client"]["url"], gameJar)) {
                 std::string errorMsg = "Failed to download client JAR: " + gameJar.string() + ". Cannot launch.";
                 if (console_attached) std::cerr << errorMsg << std::endl; else MessageBoxA(NULL, errorMsg.c_str(), "Launcher Error", MB_OK | MB_ICONERROR);
                 curl_easy_cleanup(curl); curl_global_cleanup(); if (console_attached) FreeConsole(); return 1;
            }
        } else {
             std::string errorMsg = "Client JAR URL not found in " + mcJsonPath.filename().string() + ". Cannot launch.";
             if (console_attached) std::cerr << errorMsg << std::endl; else MessageBoxA(NULL, errorMsg.c_str(), "Launcher Error", MB_OK | MB_ICONERROR);
             curl_easy_cleanup(curl); curl_global_cleanup(); if (console_attached) FreeConsole(); return 1;
        }
    }


    std::string classPathEntries = "\"" + gameJar.string();
    if (mcJson.contains("libraries") && mcJson["libraries"].is_array()) {
        if (console_attached) std::cout << "Checking/Downloading libraries..." << std::endl;
        for (const auto& lib : mcJson["libraries"]) {
            if(!lib.is_object()) continue;
            bool allow = true;
            if (lib.contains("rules") && lib["rules"].is_array()) {
                allow = false;
                std::string osName = "windows";
                for (const auto& rule_item : lib["rules"]) {
                    if(!rule_item.is_object()) continue;
                    std::string action = rule_item.value("action", "");
                    bool os_match = false;
                    if(rule_item.contains("os") && rule_item["os"].is_object() && rule_item["os"].contains("name")){
                        if(rule_item["os"]["name"] == osName) os_match = true;
                    } else { os_match = true; }
                    if(action == "allow" && os_match) allow = true;
                    if(action == "disallow" && os_match) { allow = false; break; }
                }
            }
            if (!allow) continue;

            json artifactDetails;
            bool isNative = false;
            std::string lib_path_str;
            std::string lib_url_str;

            if (lib.contains("natives") && lib["natives"].is_object() && lib["natives"].contains("windows")) {
                 std::string classifierKey = lib["natives"]["windows"];
                 if (classifierKey.find("${arch}") != std::string::npos) {
                     classifierKey.replace(classifierKey.find("${arch}"), 7, "64");
                 }
                 if (lib.contains("downloads") && lib["downloads"].is_object() &&
                     lib["downloads"].contains("classifiers") && lib["downloads"]["classifiers"].is_object() &&
                     lib["downloads"]["classifiers"].contains(classifierKey)) {
                     artifactDetails = lib["downloads"]["classifiers"][classifierKey];
                     if (artifactDetails.is_object() && artifactDetails.contains("path") && artifactDetails["path"].is_string() &&
                         artifactDetails.contains("url") && artifactDetails["url"].is_string()) {
                          lib_path_str = artifactDetails["path"].get<std::string>();
                          lib_url_str = artifactDetails["url"].get<std::string>();
                          isNative = true;
                     } else continue;
                 } else continue;
            } else if (lib.contains("downloads") && lib["downloads"].is_object() && lib["downloads"].contains("artifact")) {
                artifactDetails = lib["downloads"]["artifact"];
                 if (artifactDetails.is_object() && artifactDetails.contains("path") && artifactDetails["path"].is_string() &&
                     artifactDetails.contains("url") && artifactDetails["url"].is_string()) {
                     lib_path_str = artifactDetails["path"].get<std::string>();
                     lib_url_str = artifactDetails["url"].get<std::string>();
                 } else continue;
            } else if (lib.contains("name") && lib["name"].is_string()) {

                 std::string name = lib["name"];
                 std::string package, artifact, version, classifier;
                 size_t first_colon = name.find(':');
                 size_t second_colon = name.find(':', first_colon + 1);
                 size_t third_colon = name.find(':', second_colon + 1);

                 if (first_colon != std::string::npos && second_colon != std::string::npos) {
                     package = name.substr(0, first_colon);
                     artifact = name.substr(first_colon + 1, second_colon - first_colon - 1);
                     version = name.substr(second_colon + 1);
                     if (third_colon != std::string::npos) {
                         version = name.substr(second_colon + 1, third_colon - second_colon - 1);
                         classifier = name.substr(third_colon + 1);
                     }

                     std::replace(package.begin(), package.end(), '.', '/');
                     lib_path_str = package + "/" + artifact + "/" + version + "/" + artifact + "-" + version;
                     if (!classifier.empty()) {
                         lib_path_str += "-" + classifier;
                         isNative = true;
                     }
                     lib_path_str += ".jar";

                     std::string baseUrl = "https://libraries.minecraft.net/";
                     if (lib.contains("url") && lib["url"].is_string()) {
                        baseUrl = lib["url"];
                     }
                     lib_url_str = baseUrl + lib_path_str;
                 } else {
                     continue;
                 }

            }
             else {
                 continue;
            }

             fs::path libPath = librariesDir / lib_path_str;
             fs::create_directories(libPath.parent_path());


            if (!fs::exists(libPath)) {

                bool downloadSuccess = false;
                for (int attempt = 1; attempt <= 3; ++attempt) {
                    if (console_attached) std::cout << "Downloading library " << libPath.filename() << " (Attempt " << attempt << ")" << std::endl;
                    if (downloadFile(curl, lib_url_str, libPath)) {
                        downloadSuccess = true;
                        break;
                    }
                     if (console_attached) std::cerr << "Download attempt " << attempt << " failed for " << libPath.filename() << ". Retrying in 1 second..." << std::endl;
                    std::this_thread::sleep_for(std::chrono::seconds(1));
                }
                if (!downloadSuccess) {
                     if (console_attached) std::cerr << "Warning: Failed to download library " << libPath.filename() << " after multiple attempts. Launch might fail." << std::endl;


                }
            }

            if (isNative && fs::exists(libPath)) {
                extractZip(libPath, nativesDir);
            } else if (!isNative && fs::exists(libPath)) {
                classPathEntries += ";" + libPath.string();
            }
        }
    }
    classPathEntries += ";" + (librariesDir / "*").string() + "\"";


    std::string assetIndexId = mcJson.value("assetIndex", json::object()).value("id", "legacy");
    fs::path assetIndexPath = assetIndexesDir / (assetIndexId + ".json");
    json assetIndexJson;

    if(fs::exists(assetIndexPath)){
        std::ifstream aif(assetIndexPath);
        if (!aif.is_open()) {
             if (console_attached) std::cerr << "Error opening cached asset index: " << assetIndexPath << std::endl;
        } else {
            try {
                aif >> assetIndexJson;
                aif.close();
            } catch (const json::parse_error& e) {
                if (console_attached) std::cerr << "Error parsing cached asset index: " << e.what() << std::endl;
                aif.close();
                assetIndexJson = nullptr;
            }
        }
    }

    if((assetIndexJson.is_null() || !assetIndexJson.contains("objects")) && mcJson.contains("assetIndex") && mcJson["assetIndex"].is_object() && mcJson["assetIndex"].contains("url")){
        if (console_attached) std::cout << "Attempting to download asset index: " << assetIndexPath.filename() << std::endl;
        if(downloadFile(curl, std::string(mcJson["assetIndex"]["url"]), assetIndexPath, true)){
             std::ifstream aif_retry(assetIndexPath);
             if (aif_retry.is_open()) {
                 try {
                     aif_retry >> assetIndexJson;
                     aif_retry.close();
                 } catch (const json::parse_error& e) {
                     if (console_attached) std::cerr << "Error parsing downloaded asset index: " << e.what() << std::endl;
                     aif_retry.close();
                     assetIndexJson = nullptr;
                 }
             } else {
                 if (console_attached) std::cerr << "Failed to open downloaded asset index." << std::endl;
                 assetIndexJson = nullptr;
             }
        } else {
            if (console_attached) std::cerr << "Failed download/parse asset index " << assetIndexPath.filename() << ". Assets might be missing." << std::endl;

        }
    }


    if (assetIndexJson.contains("objects") && assetIndexJson["objects"].is_object()) {
        int totalAssets = assetIndexJson["objects"].size();
        int currentAsset = 0;
        if (console_attached) std::cout << "Checking/Downloading Assets..." << std::endl;
        for (auto const& [key, val] : assetIndexJson["objects"].items()) {
            currentAsset++;
            if (!val.is_object() || !val.contains("hash") || !val["hash"].is_string()) continue;
            std::string hash = val["hash"];
            if (hash.length() < 2) continue;
            fs::path objSubDir = assetObjectsDir / hash.substr(0, 2);
            fs::path objPath = objSubDir / hash;
            if (!fs::exists(objPath)) {
                 if (console_attached) std::cout << "[" << currentAsset << "/" << totalAssets << "] Downloading asset: " << key << " (" << hash.substr(0, 7) << ")" << std::endl;
                fs::create_directories(objSubDir);
                std::string assetUrl = "https://resources.download.minecraft.net/" + hash.substr(0, 2) + "/" + hash;

                bool assetDownloadSuccess = false;
                for (int attempt = 1; attempt <= 2; ++attempt) {
                    if (downloadFile(curl, assetUrl, objPath)) {
                        assetDownloadSuccess = true;
                        break;
                    }
                     if (attempt < 2 && console_attached) {
                         std::cerr << "Asset download attempt " << attempt << " failed for " << key << ". Retrying..." << std::endl;
                          std::this_thread::sleep_for(std::chrono::milliseconds(500));
                     }
                }
                if (!assetDownloadSuccess && console_attached) {
                    std::cerr << "Warning: Failed to download asset " << key << " after multiple attempts." << std::endl;
                }
            }
        }
         if (console_attached) std::cout << "Asset check complete." << std::endl;
    }


    std::string javaCommand = "javaw";
    bool cp_added_by_jvm_args = false;
    if (mcJson.contains("arguments") && mcJson["arguments"].is_object() && mcJson["arguments"].contains("jvm") && mcJson["arguments"]["jvm"].is_array()){
        for (const auto& arg_item : mcJson["arguments"]["jvm"]) {

             bool process_arg = true;
             if (arg_item.is_object() && arg_item.contains("rules")) {
                 process_arg = false;
                 std::string osName = "windows";
                 bool osArchMatch = false;
                 for (const auto& rule_item : arg_item["rules"]) {
                      if(!rule_item.is_object()) continue;
                      std::string action = rule_item.value("action", "");
                      bool os_match = false;
                       bool arch_match = true;


                      if(rule_item.contains("os") && rule_item["os"].is_object()){
                          if(rule_item["os"].contains("name") && rule_item["os"]["name"] == osName) os_match = true;
                           if(rule_item["os"].contains("arch") && rule_item["os"]["arch"] == "x64") arch_match = true;
                           else if (rule_item["os"].contains("arch")) arch_match = false;
                      } else {
                           os_match = true;
                      }

                     if (action == "allow" && os_match && arch_match) { process_arg = true; break; }
                     if (action == "disallow" && os_match && arch_match) { process_arg = false; break; }
                 }
             }

             if (!process_arg) continue;

             std::string arg_string_to_process;
             if (arg_item.is_string()) {
                 arg_string_to_process = arg_item.get<std::string>();
             } else if (arg_item.is_object() && arg_item.contains("value")) {
                 if (arg_item["value"].is_string()) {
                     arg_string_to_process = arg_item["value"].get<std::string>();
                 } else if (arg_item["value"].is_array()) {
                     for(const auto& sub_arg : arg_item["value"]) {
                         if (sub_arg.is_string()) {
                             javaCommand += " " + sub_arg.get<std::string>();
                         }
                     }
                     continue;
                 } else {
                     continue;
                 }
             } else {
                 continue;
             }


            size_t pos;

            while ((pos = arg_string_to_process.find("${natives_directory}")) != std::string::npos) {
                 arg_string_to_process.replace(pos, 19, "\"" + nativesDir.string() + "\"");
            }
            while ((pos = arg_string_to_process.find("${launcher_name}")) != std::string::npos) {
                 arg_string_to_process.replace(pos, 16, "MinimalLauncher");
            }
            while ((pos = arg_string_to_process.find("${launcher_version}")) != std::string::npos) {
                 arg_string_to_process.replace(pos, 19, "1.9");
            }
             while ((pos = arg_string_to_process.find("${classpath}")) != std::string::npos) {
                 arg_string_to_process.replace(pos, 12, classPathEntries);
                 cp_added_by_jvm_args = true;
             }

             javaCommand += " " + arg_string_to_process;


        }

    }

     if (javaCommand.find("-Xmx") == std::string::npos) javaCommand += " -Xmx" + maxMemory;
     if (javaCommand.find("-Xms") == std::string::npos) javaCommand += " -Xms" + minMemory;
     if (!cp_added_by_jvm_args) javaCommand += " -cp " + classPathEntries;

    javaCommand += " --enable-native-access=ALL-UNNAMED";

    if (mcJson.contains("mainClass") && mcJson["mainClass"].is_string()) {
        javaCommand += " " + mcJson["mainClass"].get<std::string>();
    } else {
         std::string errorMsg = "Error: mainClass not found or not a string in version JSON.";
         if (console_attached) std::cerr << errorMsg << std::endl; else MessageBoxA(NULL, errorMsg.c_str(), "Launcher Error", MB_OK | MB_ICONERROR);
        curl_easy_cleanup(curl); curl_global_cleanup(); if (console_attached) FreeConsole(); return 1;
    }

     if (mcJson.contains("arguments") && mcJson["arguments"].is_object() && mcJson["arguments"].contains("game") && mcJson["arguments"]["game"].is_array()) {
        for (const auto& arg_item : mcJson["arguments"]["game"]) {
            if (arg_item.is_string()) {
                std::string arg = arg_item.get<std::string>();
                 size_t pos;
                 while ((pos = arg.find("${auth_player_name}")) != std::string::npos) arg.replace(pos, 19, authDetails.mcUsername);
                 while ((pos = arg.find("${version_name}")) != std::string::npos) arg.replace(pos, 15, mcVersionInput);
                 while ((pos = arg.find("${game_directory}")) != std::string::npos) arg.replace(pos, 17, "\"" + gameDir.string() + "\"");
                 while ((pos = arg.find("${assets_root}")) != std::string::npos) arg.replace(pos, 14, "\"" + assetsDir.string() + "\"");
                 while ((pos = arg.find("${assets_index_name}")) != std::string::npos) arg.replace(pos, 20, assetIndexId);
                 while ((pos = arg.find("${auth_uuid}")) != std::string::npos) arg.replace(pos, 12, authDetails.mcUuid);
                 while ((pos = arg.find("${auth_access_token}")) != std::string::npos) arg.replace(pos, 20, authDetails.mcAccessToken);
                 while ((pos = arg.find("${clientid}")) != std::string::npos) arg.replace(pos, 11, MS_CLIENT_ID);
                 while ((pos = arg.find("${auth_xuid}")) != std::string::npos) {
                    arg.replace(pos, 11, authDetails.xuid);
                 }
                 while ((pos = arg.find("${user_type}")) != std::string::npos) arg.replace(pos, 12, "msa");
                 while ((pos = arg.find("${version_type}")) != std::string::npos) arg.replace(pos, 15, mcJson.value("type", "release"));
                 while ((pos = arg.find("${user_properties}")) != std::string::npos) arg.replace(pos, 18, "{}");

                javaCommand += " " + arg;
            } else if (arg_item.is_object()) {

                  bool process_conditional_arg = true;
                  if (arg_item.contains("rules")) {
                      process_conditional_arg = false;
                      for (const auto& rule : arg_item["rules"]) {
                          if (rule.is_object() && rule.contains("action") && rule["action"] == "allow" && rule.contains("features")) {


                          }
                      }
                  }

                 if (process_conditional_arg && arg_item.contains("value")) {
                     if (arg_item["value"].is_string()) {
                         javaCommand += " " + arg_item["value"].get<std::string>();
                     } else if (arg_item["value"].is_array()) {
                          for(const auto& sub_arg : arg_item["value"]) {
                              if (sub_arg.is_string()) {
                                  javaCommand += " " + sub_arg.get<std::string>();
                              }
                          }
                     }
                 }
            }
        }
    } else {
        javaCommand += " --username " + authDetails.mcUsername;
        javaCommand += " --version " + mcVersionInput;
        javaCommand += " --gameDir \"" + gameDir.string() + "\"";
        javaCommand += " --assetsDir \"" + assetsDir.string() + "\"";
        javaCommand += " --assetIndex " + assetIndexId;
        javaCommand += " --uuid " + authDetails.mcUuid;
        javaCommand += " --accessToken " + authDetails.mcAccessToken;
        javaCommand += " --clientId " + MS_CLIENT_ID;
        javaCommand += " --xuid " + authDetails.xuid;
        javaCommand += " --userType msa";
        javaCommand += " --versionType " + mcJson.value("type", "release");
         javaCommand += " --userProperties {}";
    }


    if (mcJson.contains("logging") && mcJson["logging"].is_object() && mcJson["logging"].contains("client") && mcJson["logging"]["client"].is_object()) {
        json clientLog = mcJson["logging"]["client"];
        if(clientLog.contains("file") && clientLog["file"].is_object() && clientLog["file"].contains("id") && clientLog["file"].contains("url") && clientLog.contains("argument")){
             if (clientLog["file"]["id"].is_string() && clientLog["file"]["url"].is_string() && clientLog["argument"].is_string()) {
                 std::string logConfigFileId = clientLog["file"]["id"];
                 fs::path logConfigPath = assetsDir / "log_configs" / logConfigFileId;
                 if (!fs::exists(logConfigPath.parent_path())) fs::create_directories(logConfigPath.parent_path());
                 if (!fs::exists(logConfigPath)){

                    if (!downloadFile(curl, std::string(clientLog["file"]["url"]), logConfigPath, true)) {
                         if (console_attached) std::cerr << "Warning: Failed to download logging configuration " << logConfigFileId << ". Logging might not work as expected." << std::endl;

                    }
                 }
                 if(fs::exists(logConfigPath)){
                    std::string logArg = clientLog["argument"];
                    size_t placeholderPos = logArg.find("${path}");
                    if (placeholderPos != std::string::npos) {
                        logArg.replace(placeholderPos, std::string("${path}").length(), "\"" + logConfigPath.string() + "\"");
                    }
                     javaCommand += " " + logArg;
                 }
             }
        }
    }


    if (console_attached) {
        std::cout << "Final Command (before redirection): " << javaCommand.substr(0,512) << (javaCommand.length() > 512 ? "..." : "") << std::endl;
    }


    javaCommand += " > minecraft_launch.log 2>&1";

    if (console_attached) {
        if (required_manual_login) {
             std::cout << "Launched after manual login. Launching Minecraft..." << std::endl;
        } else {
             std::cout << "Login successful via refresh token. Launching Minecraft..." << std::endl;
             std::cout << "(Launcher console will detach immediately after launch)" << std::endl;
        }
    }

    STARTUPINFOA si;
    PROCESS_INFORMATION pi;
    ZeroMemory(&si, sizeof(si));
    si.cb = sizeof(si);
    ZeroMemory(&pi, sizeof(pi));

    std::vector<char> cmd_buffer(javaCommand.begin(), javaCommand.end());
    cmd_buffer.push_back('\0');


    int result = 0;
    if (!CreateProcessA(NULL,
                        cmd_buffer.data(),
                        NULL,
                        NULL,
                        FALSE,
                        CREATE_NO_WINDOW,
                        NULL,
                        NULL,
                        &si,
                        &pi))
    {
        result = GetLastError();
        std::string errorMsg = "CreateProcess failed (" + std::to_string(result) + "). Cannot launch Minecraft.";
        if (console_attached) std::cerr << errorMsg << std::endl; else MessageBoxA(NULL, errorMsg.c_str(), "Launcher Error", MB_OK | MB_ICONERROR);

    } else {

        CloseHandle(pi.hProcess);
        CloseHandle(pi.hThread);
        result = 0;
    }


    if (result != 0) {

        std::string errorMsg = "Minecraft process failed or exited with an error. Exit code: " + std::to_string(result) + ". Check minecraft_launch.log for details.";
         if (console_attached) {
            std::cerr << errorMsg << std::endl;

         } else {
            MessageBoxA(NULL, errorMsg.c_str(), "Launcher Error", MB_OK | MB_ICONERROR);
         }
    } else {

        if (console_attached && !required_manual_login) {

             if (console_attached) std::cout << "Detaching launcher console..." << std::endl;
             std::this_thread::sleep_for(std::chrono::milliseconds(500));
             FreeConsole();
             console_attached = false;
         }

    }


    curl_easy_cleanup(curl);
    curl_global_cleanup();


    if (console_attached) {
         FreeConsole();
    }

    return (result == 0) ? 0 : 1;
}

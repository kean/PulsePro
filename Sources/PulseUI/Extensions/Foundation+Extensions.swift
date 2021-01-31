// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).
// Licensed under Apache License v2.0 with Runtime Library Exception.

import Foundation

extension tls_ciphersuite_t {
    var description: String {
        switch self {
        case .RSA_WITH_3DES_EDE_CBC_SHA: return "RSA_WITH_3DES_EDE_CBC_SHA"
        case .RSA_WITH_AES_128_CBC_SHA: return "RSA_WITH_AES_128_CBC_SHA"
        case .RSA_WITH_AES_256_CBC_SHA: return "RSA_WITH_AES_256_CBC_SHA"
        case .RSA_WITH_AES_128_GCM_SHA256: return "RSA_WITH_AES_128_GCM_SHA256"
        case .RSA_WITH_AES_256_GCM_SHA384: return "RSA_WITH_AES_256_GCM_SHA384"
        case .RSA_WITH_AES_128_CBC_SHA256: return "RSA_WITH_AES_128_CBC_SHA256"
        case .RSA_WITH_AES_256_CBC_SHA256: return "RSA_WITH_AES_256_CBC_SHA256"
        case .ECDHE_ECDSA_WITH_3DES_EDE_CBC_SHA: return "ECDHE_ECDSA_WITH_3DES_EDE_CBC_SHA"
        case .ECDHE_ECDSA_WITH_AES_128_CBC_SHA: return "ECDHE_ECDSA_WITH_AES_128_CBC_SHA"
        case .ECDHE_ECDSA_WITH_AES_256_CBC_SHA: return "ECDHE_ECDSA_WITH_AES_256_CBC_SHA"
        case .ECDHE_RSA_WITH_3DES_EDE_CBC_SHA: return "ECDHE_RSA_WITH_3DES_EDE_CBC_SHA"
        case .ECDHE_RSA_WITH_AES_128_CBC_SHA: return "ECDHE_RSA_WITH_AES_128_CBC_SHA"
        case .ECDHE_RSA_WITH_AES_256_CBC_SHA: return "ECDHE_RSA_WITH_AES_256_CBC_SHA"
        case .ECDHE_ECDSA_WITH_AES_128_CBC_SHA256: return "ECDHE_ECDSA_WITH_AES_128_CBC_SHA256"
        case .ECDHE_ECDSA_WITH_AES_256_CBC_SHA384: return "ECDHE_ECDSA_WITH_AES_256_CBC_SHA384"
        case .ECDHE_RSA_WITH_AES_128_CBC_SHA256: return "ECDHE_RSA_WITH_AES_128_CBC_SHA256"
        case .ECDHE_RSA_WITH_AES_256_CBC_SHA384: return "ECDHE_RSA_WITH_AES_256_CBC_SHA384"
        case .ECDHE_ECDSA_WITH_AES_128_GCM_SHA256: return "ECDHE_ECDSA_WITH_AES_128_GCM_SHA256"
        case .ECDHE_ECDSA_WITH_AES_256_GCM_SHA384: return "ECDHE_ECDSA_WITH_AES_256_GCM_SHA384"
        case .ECDHE_RSA_WITH_AES_128_GCM_SHA256: return "ECDHE_RSA_WITH_AES_128_GCM_SHA256"
        case .ECDHE_RSA_WITH_AES_256_GCM_SHA384: return "ECDHE_RSA_WITH_AES_256_GCM_SHA384"
        case .ECDHE_RSA_WITH_CHACHA20_POLY1305_SHA256: return "ECDHE_RSA_WITH_CHACHA20_POLY1305_SHA256"
        case .ECDHE_ECDSA_WITH_CHACHA20_POLY1305_SHA256: return "ECDHE_ECDSA_WITH_CHACHA20_POLY1305_SHA256"
        case .AES_128_GCM_SHA256: return "AES_128_GCM_SHA256"
        case .AES_256_GCM_SHA384: return "AES_256_GCM_SHA384"
        case .CHACHA20_POLY1305_SHA256: return "CHACHA20_POLY1305_SHA256"
        @unknown default: return "Unknown"
        }
    }
}

extension tls_protocol_version_t {
    var description: String {
        switch self {
        case .TLSv10: return "TLS 1.0"
        case .TLSv11: return "TLS 1.1"
        case .TLSv12: return "TLS 1.2"
        case .TLSv13: return "TLS 1.3"
        case .DTLSv10: return "DTLS 1.0"
        case .DTLSv12: return "DTLS 1.2"
        @unknown default: return "Unknown"
        }
    }
}

func descriptionForURLErrorCode(_ code: Int) -> String {
    switch code {
    case NSURLErrorUnknown: return "URLErrorUnknown"
    case NSURLErrorCancelled: return "URLErrorCancelled"
    case NSURLErrorBadURL: return "URLErrorBadURL"
    case NSURLErrorTimedOut: return "URLErrorTimedOut"
    case NSURLErrorUnsupportedURL: return "URLErrorUnsupportedURL"
    case NSURLErrorCannotFindHost: return "URLErrorCannotFindHost"
    case NSURLErrorCannotConnectToHost: return "URLErrorCannotConnectToHost"
    case NSURLErrorNetworkConnectionLost: return "URLErrorNetworkConnectionLost"
    case NSURLErrorDNSLookupFailed: return "URLErrorDNSLookupFailed"
    case NSURLErrorHTTPTooManyRedirects: return "URLErrorHTTPTooManyRedirects"
    case NSURLErrorResourceUnavailable: return "URLErrorResourceUnavailable"
    case NSURLErrorNotConnectedToInternet: return "URLErrorNotConnectedToInternet"
    case NSURLErrorRedirectToNonExistentLocation: return "URLErrorRedirectToNonExistentLocation"
    case NSURLErrorBadServerResponse: return "URLErrorBadServerResponse"
    case NSURLErrorUserCancelledAuthentication: return "URLErrorUserCancelledAuthentication"
    case NSURLErrorUserAuthenticationRequired: return "URLErrorUserAuthenticationRequired"
    case NSURLErrorZeroByteResource: return "URLErrorZeroByteResource"
    case NSURLErrorCannotDecodeRawData: return "URLErrorCannotDecodeRawData"
    case NSURLErrorCannotDecodeContentData: return "URLErrorCannotDecodeContentData"
    case NSURLErrorCannotParseResponse: return "URLErrorCannotParseResponse"
    case NSURLErrorAppTransportSecurityRequiresSecureConnection: return "URLErrorAppTransportSecurityRequiresSecureConnection"
    case NSURLErrorFileDoesNotExist: return "URLErrorFileDoesNotExist"
    case NSURLErrorFileIsDirectory: return "URLErrorFileIsDirectory"
    case NSURLErrorNoPermissionsToReadFile: return "URLErrorNoPermissionsToReadFile"
    case NSURLErrorDataLengthExceedsMaximum: return "URLErrorDataLengthExceedsMaximum"
    case NSURLErrorFileOutsideSafeArea: return "URLErrorFileOutsideSafeArea"
    case NSURLErrorSecureConnectionFailed: return "URLErrorSecureConnectionFailed"
    case NSURLErrorServerCertificateHasBadDate: return "URLErrorServerCertificateHasBadDate"
    case NSURLErrorServerCertificateUntrusted: return "URLErrorServerCertificateUntrusted"
    case NSURLErrorServerCertificateHasUnknownRoot: return "URLErrorServerCertificateHasUnknownRoot"
    case NSURLErrorServerCertificateNotYetValid: return "URLErrorServerCertificateNotYetValid"
    case NSURLErrorClientCertificateRejected: return "URLErrorClientCertificateRejected"
    case NSURLErrorClientCertificateRequired: return "URLErrorClientCertificateRequired"
    case NSURLErrorCannotLoadFromNetwork: return "URLErrorCannotLoadFromNetwork"
    case NSURLErrorCannotCreateFile: return "URLErrorCannotCreateFile"
    case NSURLErrorCannotOpenFile: return "URLErrorCannotOpenFile"
    case NSURLErrorCannotCloseFile: return "URLErrorCannotCloseFile"
    case NSURLErrorCannotWriteToFile: return "URLErrorCannotWriteToFile"
    case NSURLErrorCannotRemoveFile: return "URLErrorCannotRemoveFile"
    case NSURLErrorCannotMoveFile: return "URLErrorCannotMoveFile"
    case NSURLErrorDownloadDecodingFailedMidStream: return "URLErrorDownloadDecodingFailedMidStream"
    case NSURLErrorDownloadDecodingFailedToComplete: return "URLErrorDownloadDecodingFailedToComplete"
    case NSURLErrorInternationalRoamingOff: return "URLErrorInternationalRoamingOff"
    case NSURLErrorCallIsActive: return "URLErrorCallIsActive"
    case NSURLErrorDataNotAllowed: return "URLErrorDataNotAllowed"
    case NSURLErrorRequestBodyStreamExhausted: return "URLErrorRequestBodyStreamExhausted"
    case NSURLErrorBackgroundSessionRequiresSharedContainer: return "URLErrorBackgroundSessionRequiresSharedContainer"
    case NSURLErrorBackgroundSessionInUseByAnotherProcess: return "URLErrorBackgroundSessionInUseByAnotherProcess"
    case NSURLErrorBackgroundSessionWasDisconnected: return "URLErrorBackgroundSessionWasDisconnected"
    default: return "Unknown"
    }
}

extension URLRequest.CachePolicy {
    var description: String {
        switch self {
        case .useProtocolCachePolicy: return "useProtocolCachePolicy"
        case .reloadIgnoringLocalCacheData: return "reloadIgnoringLocalCacheData"
        case .reloadIgnoringLocalAndRemoteCacheData: return "reloadIgnoringLocalAndRemoteCacheData"
        case .returnCacheDataElseLoad: return "returnCacheDataElseLoad"
        case .returnCacheDataDontLoad: return "returnCacheDataDontLoad"
        case .reloadRevalidatingCacheData: return "reloadRevalidatingCacheData"
        @unknown default: return "unknown"
        }
    }
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}

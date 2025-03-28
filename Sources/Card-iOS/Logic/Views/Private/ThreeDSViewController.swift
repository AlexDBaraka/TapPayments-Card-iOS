//
//  ThreeDSViewController.swift
//  TapCardCheckOutKit
//
//  Created by Osama Rabie on 12/09/2023.
//

import UIKit
import WebKit
import SharedDataModels_iOS

class ThreeDSView: UIView {

    /// The web view used to render the 3ds page
    var webView: WKWebView?
    /// The details containitng both threeds and redirect urls
    var cardRedirectionData:CardRedirection = .init()
    /// The timer used to check if no redirection is being called for the last 3 seconds
    var timer: Timer?
    /// The delay that we should wait for to decide if it is idle in  seonds
    var delayTime:CGFloat = 3.000
    /// A custom action block to execute when nothing else being loaded for a while
    var idleForWhile:()->() = {}
    /// A custom action block to execute when nothing else being loaded for a while
    var redirectionReached:(String)->() = { _ in }
    /// A custom action block to execute when the user cancels the authentication
    var threeDSCanceled:()->() = {}
    /// The powered by tap view
    var poweredByTapView:PoweredByTapView = .init(frame: .zero)
    /// Represents the locale needed to render the powered by tap view with
    var selectedLocale:String = "en" {
        didSet{
            self.poweredByTapView.selectedLocale = selectedLocale
        }
    }
    
    //MARK: - Init methods
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    //MARK: - Private methods
    /// Used as a consolidated method to do all the needed steps upon creating the view
    private func commonInit() {
        themeController()
        themeWebView()
        webViewConstraints()
        poweredByTapViewConstraints()
        poweredByTapView.backButtonClicked = {
            self.threeDSCanceled()
        }
    }
    
    
    /// Starts loading the urls
    func startLoading() {
        webView?.load(URLRequest(url: URL(string: cardRedirectionData.threeDsUrl!)!))
    }
}


// MARK: - UI & Constraints
extension ThreeDSView {
    /// Applies theme on controller level
    func themeController() {
        backgroundColor = .clear
    }
    
    /// Applies theme on web view level
    func themeWebView() {
        webView = .init(frame: .zero)
        webView?.isOpaque = false
        webView?.backgroundColor = UIColor.white
        webView?.scrollView.backgroundColor = UIColor.clear
        webView?.scrollView.bounces = false
        webView?.navigationDelegate = self
        webView?.layer.cornerRadius = 0
        webView?.clipsToBounds = true
    }
    /// Applies constrains to correctly size and position the web view
    func webViewConstraints() {
        addSubview(webView!)
        webView?.translatesAutoresizingMaskIntoConstraints = false
        
        DispatchQueue.main.async {
            self.webView?.setNeedsLayout()
            self.webView?.updateConstraints()
            self.setNeedsLayout()
        }
    }
    
    
    /// Applies constrains to correctly size and position the web view
    func poweredByTapViewConstraints() {
        addSubview(poweredByTapView)
        sendSubviewToBack(poweredByTapView)
        poweredByTapView.translatesAutoresizingMaskIntoConstraints = false
        
        DispatchQueue.main.async {
            self.poweredByTapView.setNeedsLayout()
            self.poweredByTapView.updateConstraints()
            self.setNeedsLayout()
        }
    }
}

// MARK: - WebView delegate
extension ThreeDSView: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        // Check if it is the return url
        
        if let requestURL:URL = navigationAction.request.url,
           let triggerKeyword:String = cardRedirectionData.keyword,
           let waitedKeyword:String = triggeringValue(from: requestURL, with: triggerKeyword),
           !waitedKeyword.isEmpty {
            self.redirectionReached(requestURL.absoluteString)
            decisionHandler(.cancel)
            return
        }
        decisionHandler(.allow)
    }
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let timer = timer {
            timer.invalidate()
        }
        
        timer = Timer.scheduledTimer(withTimeInterval: delayTime, repeats: false, block: { (timer) in
            timer.invalidate()
            self.idleForWhile()
        })
    }
    
    
    
    func triggeringValue(from url:URL, with triggeringKeyword:String) -> String? {
        return tap_extractDataFromUrl(url,for:triggeringKeyword, shouldBase64Decode: false)
    }
}

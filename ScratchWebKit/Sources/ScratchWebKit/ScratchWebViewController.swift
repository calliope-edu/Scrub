//
//  ScratchWebViewController.swift
//  Scrub
//
//  Created by Shinichiro Oba on 2021/04/02.
//

import UIKit
import WebKit
import Combine
import ScratchLinkKit
import WebMIDIKit
import UniformTypeIdentifiers

public enum ScratchWebViewError: Error {
    case forbiddenAccess(url: URL)
}

extension ScratchWebViewError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .forbiddenAccess:
            return NSLocalizedString("Not allowed to access this URL", bundle: Bundle.module, comment: "Not allowed to access this URL")
        }
    }
}

// MARK: - Console Log Handler
private class ConsoleLogHandler: NSObject, WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        print("🌐 JS: \(message.body)")
    }
}

// MARK: - ScratchWebViewController
public class ScratchWebViewController: WebViewController {
    
    public weak var delegate: ScratchWebViewControllerDelegate?
    
    private let scratchLink = ScratchLink()
    private let webMidi = WebMIDI()
    
    private var downloadingUrl: URL? = nil
    
    private var cancellables: Set<AnyCancellable> = []
    
    private var sizeConstraints: [NSLayoutConstraint] = []
    
    // Handler für Console-Logs
    private let consoleLogHandler = ConsoleLogHandler()
    
    public override init() {
        super.init()
        
        // WICHTIG: Console-Bridge ZUERST einrichten
        setupConsoleLogBridge()
        
        scratchLink.setup(webView: webView)
        scratchLink.delegate = self
        
        webMidi.setup(webView: webView)
        
        // JavaScript Injection für File-Input Fix
        setupFileInputFix()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Console Log Bridge
    
    private func setupConsoleLogBridge() {
        let script = """
        (function() {
            var originalLog = console.log;
            console.log = function() {
                var message = Array.from(arguments).map(arg => 
                    typeof arg === 'object' ? JSON.stringify(arg) : String(arg)
                ).join(' ');
                window.webkit.messageHandlers.consoleLog.postMessage(message);
                originalLog.apply(console, arguments);
            };
        })();
        """
        
        let userScript = WKUserScript(source: script, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        webView.configuration.userContentController.addUserScript(userScript)
        webView.configuration.userContentController.add(consoleLogHandler, name: "consoleLog")
    }
    
    // MARK: - File Input Fix
    
    private func setupFileInputFix() {
        let script = """
        (function() {
            console.log('File input fixer starting...');
            
            var observer = new MutationObserver(function(mutations) {
                mutations.forEach(function(mutation) {
                    mutation.addedNodes.forEach(function(node) {
                        if (node.nodeType === 1) {
                            fixFileInputs(node);
                        }
                    });
                });
            });
            
            function fixFileInputs(root) {
                var inputs = root.querySelectorAll ? root.querySelectorAll('input[type="file"]') : 
                              (root.tagName === 'INPUT' && root.type === 'file' ? [root] : []);
                
                inputs.forEach(function(input) {
                    var originalAccept = input.accept;
                    
                    if (originalAccept) {
                        console.log('Original accept:', originalAccept);
                        
                        var newAccept = originalAccept;
                        if (!newAccept.includes('.sprite3')) {
                            newAccept += ',.sprite3';
                        }
                        if (!newAccept.includes('.sprite2')) {
                            newAccept += ',.sprite2';
                        }
                        if (!newAccept.includes('.sb3')) {
                            newAccept += ',.sb3';
                        }
                        if (!newAccept.includes('.sb2')) {
                            newAccept += ',.sb2';
                        }
                        
                        input.accept = newAccept;
                        console.log('New accept:', input.accept);
                    }
                });
            }
            
            fixFileInputs(document);
            
            if (document.body) {
                observer.observe(document.body, {
                    childList: true,
                    subtree: true
                });
            } else {
                document.addEventListener('DOMContentLoaded', function() {
                    fixFileInputs(document);
                    observer.observe(document.body, {
                        childList: true,
                        subtree: true
                    });
                });
            }
            
            console.log('File input fixer installed');
        })();
        """
        
        let userScript = WKUserScript(
            source: script,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: false
        )
        
        webView.configuration.userContentController.addUserScript(userScript)
    }
    
    // MARK: - Backpack Debug Script
    
private func injectBackpackTouchFix() {
        let script = getBackpackTouchFixScript()
        
        webView.evaluateJavaScript(script) { (result, error) in
            if let error = error {
                print("Backpack Touch Fix Fehler: \(error)")
            } else {
                print("Backpack Touch Fix aktiviert")
            }
        }
    }

    private func getBackpackTouchFixScript() -> String {
        return """
        (function() {
            if (window.__BACKPACK_TOUCH_FIX_INSTALLED__) return;
            window.__BACKPACK_TOUCH_FIX_INSTALLED__ = true;
            
            var isDraggingBlock = false;
            var isDraggingFromBackpack = false;
            var currentBlockId = null;
            var currentBackpackItem = null;
            var currentBackpackItemIndex = -1;
            var blocklyMainWorkspace = null;
            var vm = null;
            var backpackInstance = null;
            var backpackList = null;
            var isOverBackpack = false;
            
            function findVM() {
                var guiWrapper = document.querySelector('[class*="gui_body-wrapper"]');
                if (!guiWrapper) return null;
                var fiberKey = Object.keys(guiWrapper).find(function(key) {
                    return key.startsWith('__reactFiber') || key.startsWith('__reactInternalInstance');
                });
                if (!fiberKey) return null;
                var fiber = guiWrapper[fiberKey];
                var current = fiber;
                for (var i = 0; i < 100 && current; i++) {
                    if (current.memoizedProps && current.memoizedProps.vm) {
                        return current.memoizedProps.vm;
                    }
                    current = current.return;
                }
                return null;
            }
            
            function generateBlockThumbnail(block) {
                try {
                    var blockSvg = block.getSvgRoot ? block.getSvgRoot() : null;
                    if (!blockSvg) return null;
                    var clone = blockSvg.cloneNode(true);
                    var svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
                    var bbox = blockSvg.getBBox();
                    svg.setAttribute('width', bbox.width + 10);
                    svg.setAttribute('height', bbox.height + 10);
                    svg.setAttribute('viewBox', (bbox.x - 5) + ' ' + (bbox.y - 5) + ' ' + (bbox.width + 10) + ' ' + (bbox.height + 10));
                    svg.setAttribute('xmlns', 'http://www.w3.org/2000/svg');
                    clone.removeAttribute('transform');
                    svg.appendChild(clone);
                    return new XMLSerializer().serializeToString(svg);
                } catch(e) {
                    return null;
                }
            }
            
            function findBackpackInstance() {
                var container = document.querySelector('[class*="backpack_backpack-container"]');
                if (!container) return null;
                var fiberKey = Object.keys(container).find(function(key) {
                    return key.startsWith('__reactFiber') || key.startsWith('__reactInternalInstance');
                });
                if (!fiberKey) return null;
                var current = container[fiberKey];
                for (var i = 0; i < 100 && current; i++) {
                    if (current.stateNode && current.stateNode.state && current.stateNode.state.contents !== undefined) {
                        return current.stateNode;
                    }
                    current = current.return;
                }
                return null;
            }
            
            function findBackpackItemAtPosition(x, y) {
                var list = document.querySelector('[class*="backpack_backpack-list"]');
                if (!list) return -1;
                var items = list.querySelectorAll('[class*="sprite-selector-item_sprite-selector-item"]');
                if (items.length === 0) items = list.querySelectorAll('[class*="selector_list-item"]');
                if (items.length === 0) items = list.querySelectorAll('div[class*="sprite-selector-item"]');
                for (var i = 0; i < items.length; i++) {
                    var rect = items[i].getBoundingClientRect();
                    if (x >= rect.left && x <= rect.right && y >= rect.top && y <= rect.bottom) {
                        return i;
                    }
                }
                return -1;
            }
            
            function addToBackpack(blockXml, thumbnail) {
                backpackInstance = findBackpackInstance();
                if (!backpackInstance) return;
                var bodyUrl = 'data:application/xml;base64,' + btoa(unescape(encodeURIComponent(blockXml)));
                var thumbUrl = thumbnail ? 'data:image/svg+xml;base64,' + btoa(unescape(encodeURIComponent(thumbnail))) : '';
                var item = {
                    type: 'script',
                    name: 'Script',
                    body: blockXml,
                    bodyUrl: bodyUrl,
                    mime: 'application/xml',
                    thumbnail: thumbUrl,
                    thumbnailUrl: thumbUrl
                };
                var contents = backpackInstance.state.contents || [];
                backpackInstance.setState({ contents: contents.concat([item]), loading: false });
            }
            
            function insertFromBackpack(item, clientX, clientY) {
                if (!item.body || !blocklyMainWorkspace) return;
                try {
                    var xml = '<xml xmlns="https://developers.google.com/blockly/xml">' + item.body + '</xml>';
                    var doc = new DOMParser().parseFromString(xml, 'text/xml');
                    var svg = blocklyMainWorkspace.getParentSvg();
                    var rect = svg.getBoundingClientRect();
                    var metrics = blocklyMainWorkspace.getMetrics();
                    var scale = blocklyMainWorkspace.scale || 1;
                    var x = ((clientX - rect.left) / scale) + (metrics.viewLeft || 0);
                    var y = ((clientY - rect.top) / scale) + (metrics.viewTop || 0);
                    var block = doc.querySelector('block');
                    if (block) {
                        block.setAttribute('x', Math.round(x));
                        block.setAttribute('y', Math.round(y));
                    }
                    Blockly.Xml.domToWorkspace(doc.documentElement, blocklyMainWorkspace);
                } catch(e) {}
            }
            
            function setup() {
                vm = findVM();
                if (!vm || !document.querySelector('.blocklyWorkspace')) {
                    setTimeout(setup, 1000);
                    return;
                }
                if (typeof Blockly !== 'undefined' && Blockly.getMainWorkspace) {
                    blocklyMainWorkspace = Blockly.getMainWorkspace();
                }
                backpackInstance = findBackpackInstance();
                
                document.addEventListener('touchstart', function(e) {
                    var touch = e.touches[0];
                    var target = e.target;
                    var bpList = document.querySelector('[class*="backpack_backpack-list"]');
                    
                    if (bpList && bpList.contains(target)) {
                        backpackInstance = findBackpackInstance();
                        var idx = findBackpackItemAtPosition(touch.clientX, touch.clientY);
                        if (idx >= 0 && backpackInstance && backpackInstance.state.contents && idx < backpackInstance.state.contents.length) {
                            isDraggingFromBackpack = true;
                            currentBackpackItemIndex = idx;
                            currentBackpackItem = backpackInstance.state.contents[idx];
                        }
                        return;
                    }
                    
                    var block = target.closest('.blocklyDraggable');
                    if (block) {
                        isDraggingBlock = true;
                        var g = target.closest('g[data-id]');
                        if (g) currentBlockId = g.getAttribute('data-id');
                    }
                }, true);
                
                document.addEventListener('touchmove', function(e) {
                    var touch = e.touches[0];
                    if (isDraggingBlock) {
                        backpackList = document.querySelector('[class*="backpack_backpack-list"]') || document.querySelector('[class*="backpack_backpack-container"]');
                        if (backpackList) {
                            var rect = backpackList.getBoundingClientRect();
                            var over = touch.clientX >= rect.left && touch.clientX <= rect.right && touch.clientY >= rect.top && touch.clientY <= rect.bottom;
                            if (over && !isOverBackpack) {
                                isOverBackpack = true;
                                backpackList.style.backgroundColor = 'rgba(76, 151, 255, 0.3)';
                            } else if (!over && isOverBackpack) {
                                isOverBackpack = false;
                                backpackList.style.backgroundColor = '';
                            }
                        }
                    }
                }, true);
                
                document.addEventListener('touchend', function(e) {
                    var touch = e.changedTouches[0];
                    
                    if (isDraggingBlock && backpackList) {
                        var rect = backpackList.getBoundingClientRect();
                        if (touch.clientX >= rect.left && touch.clientX <= rect.right && touch.clientY >= rect.top && touch.clientY <= rect.bottom && currentBlockId) {
                            var block = blocklyMainWorkspace.getBlockById(currentBlockId);
                            if (block) {
                                var dom = Blockly.Xml.workspaceToDom(blocklyMainWorkspace);
                                var fullXml = Blockly.Xml.domToText(dom);
                                var doc = new DOMParser().parseFromString(fullXml, 'text/xml');
                                var el = doc.querySelector('block[id="' + block.id + '"]');
                                if (el) {
                                    el.removeAttribute('x');
                                    el.removeAttribute('y');
                                    var xml = new XMLSerializer().serializeToString(el).replace(/ xmlns="[^"]*"/g, '');
                                    addToBackpack(xml, generateBlockThumbnail(block));
                                }
                            }
                        }
                        backpackList.style.backgroundColor = '';
                    }
                    
                    if (isDraggingFromBackpack && currentBackpackItem) {
                        var blocks = document.querySelector('[class*="blocks_blocks"]');
                        if (blocks) {
                            var rect = blocks.getBoundingClientRect();
                            if (touch.clientX >= rect.left && touch.clientX <= rect.right && touch.clientY >= rect.top && touch.clientY <= rect.bottom) {
                                insertFromBackpack(currentBackpackItem, touch.clientX, touch.clientY);
                            }
                        }
                    }
                    
                    isDraggingBlock = false;
                    isDraggingFromBackpack = false;
                    isOverBackpack = false;
                    currentBlockId = null;
                    currentBackpackItem = null;
                    currentBackpackItemIndex = -1;
                }, true);
            }
            
            setTimeout(setup, 2000);
        })();
        """
    }
    
    
    
    // MARK: - View Lifecycle
    
    public override func loadView() {
        self.view = UIView(frame: .zero)
        
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)
        
        NSLayoutConstraint.activate([
            webView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            webView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
        updateSizeConstraints(multiplier: 1)
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        $url.compactMap({$0}).sink() { [weak self] (url) in
            if self?.webView.isLoading == false {
                self?.didChangeUrl(url)
            }
        }.store(in: &cancellables)
        
        webView.navigationDelegate = self
        webView.scrollView.contentInsetAdjustmentBehavior = .never
    }
    
    public override func viewWillLayoutSubviews() {
        let multiplier = max(1.0, 1092.0 / view.bounds.width)
        updateSizeConstraints(multiplier: multiplier)
        webView.transform = CGAffineTransform(scaleX: 1.0 / multiplier, y: 1.0 / multiplier)
    }
    
    // MARK: - Private Helpers
    
    private func updateSizeConstraints(multiplier: CGFloat) {
        NSLayoutConstraint.deactivate(sizeConstraints)
        self.sizeConstraints = [
            webView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: multiplier),
            webView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: multiplier),
        ]
        NSLayoutConstraint.activate(sizeConstraints)
    }
    
    private func didChangeUrl(_ url: URL) {
        detectScratchEditor { (isScratchEditor) in
            self.delegate?.scratchWebViewController(self, decidePolicyFor: url, isScratchEditor: isScratchEditor) { (policy) in
                switch policy {
                case .allow:
                    self.webView.isUserInteractionEnabled = true
                    self.webView.alpha = 1.0
                    self.changeWebViewStyle(isScratchEditor: isScratchEditor)
                case .deny:
                    self.webView.isUserInteractionEnabled = false
                    self.webView.alpha = 0.4
                    self.delegate?.scratchWebViewController(self, didFail: ScratchWebViewError.forbiddenAccess(url: url))
                }
            }
        }
    }
    
    private func detectScratchEditor(completion: @escaping (Bool) -> Void) {
        let condition = "document.getElementById('scratch-link-extension-script') != null"
        
        webView.evaluateJavaScript(condition) { (result, error) in
            let isScratchEditor = result as? Bool ?? false
            completion(isScratchEditor)
        }
    }
    
    private func changeWebViewStyle(isScratchEditor: Bool) {
        if isScratchEditor {
            webView.evaluateJavaScript("document.documentElement.style.webkitUserSelect='none'")
            webView.evaluateJavaScript("document.documentElement.style.webkitTouchCallout='none'")
        } else {
            webView.evaluateJavaScript("document.documentElement.style.webkitUserSelect='auto'")
            webView.evaluateJavaScript("document.documentElement.style.webkitTouchCallout='inherit'")
        }
    }
    
    private func isEditingPage(completion: @escaping (Bool) -> Void) {
        let condition = "typeof window.onbeforeunload === 'function' && window.onbeforeunload(new Event('beforeunload'))"
        webView.evaluateJavaScript(condition) { value, _ in
            completion((value as? Bool) == true)
        }
    }
    
    private func confirmLoadUrl(_ decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        let alertController = UIAlertController(title: "", message: NSLocalizedString("Are you sure you want to leave this page?", bundle: Bundle.module, comment: ""), preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: NSLocalizedString("Stay", bundle: Bundle.module, comment: ""), style: .cancel) { _ in
            decisionHandler(.cancel)
        }
        let okAction = UIAlertAction(title: NSLocalizedString("Leave", bundle: Bundle.module, comment: ""), style: .default) { _ in
            decisionHandler(.allow)
        }
        alertController.addAction(cancelAction)
        alertController.addAction(okAction)
        alertController.preferredAction = okAction
        
        present(alertController, animated: true)
    }
}

// MARK: - WKNavigationDelegate
extension ScratchWebViewController: WKNavigationDelegate {
    
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if navigationAction.shouldPerformDownload {
            decisionHandler(.download)
        } else if navigationAction.targetFrame?.isMainFrame == true {
            isEditingPage { [weak self] isEditing in
                if isEditing {
                    self?.confirmLoadUrl(decisionHandler)
                } else {
                    decisionHandler(.allow)
                }
            }
        } else {
            decisionHandler(.allow)
        }
    }
    
    public func webView(_ webView: WKWebView, navigationAction: WKNavigationAction, didBecome download: WKDownload) {
        download.delegate = self
    }
    
    public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        scratchLink.closeAllSessions()
        webMidi.reset()
    }
    
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let url = webView.url {
            didChangeUrl(url)
        }
        
        // Debug-Script nach dem Laden injizieren
        injectBackpackTouchFix()
    }
    
    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        delegate?.scratchWebViewController(self, didFail: error)
    }
    
    public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        delegate?.scratchWebViewController(self, didFail: error)
    }
}

// MARK: - WKDownloadDelegate
extension ScratchWebViewController: WKDownloadDelegate {
    
    public func download(_ download: WKDownload, decideDestinationUsing response: URLResponse, suggestedFilename: String, completionHandler: @escaping (URL?) -> Void) {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(suggestedFilename)
        if FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.removeItem(atPath: url.path)
        }
        self.downloadingUrl = url
        completionHandler(url)
    }
    
    public func downloadDidFinish(_ download: WKDownload) {
        if let url = downloadingUrl {
            self.downloadingUrl = nil
            delegate?.scratchWebViewController(self, didDownloadFileAt: url)
        }
    }
    
    public func download(_ download: WKDownload, didFailWithError error: Error, resumeData: Data?) {
        delegate?.scratchWebViewController(self, didFail: error)
    }
}

// MARK: - ScratchLinkDelegate
extension ScratchWebViewController: ScratchLinkDelegate {
    
    public func canStartSession(type: SessionType) -> Bool {
        return delegate?.scratchWebViewController(self, canStartScratchLinkSessionType: type) ?? true
    }
    
    public func didStartSession(type: SessionType) {
        delegate?.scratchWebViewController(self, didStartScratchLinkSessionType: type)
    }
    
    public func didFailStartingSession(type: SessionType, error: SessionError) {
        delegate?.scratchWebViewController(self, didFailStartingScratchLinkSession: type, error: error)
    }
}

// MARK: - Types and Protocols

public enum WebFilterPolicy {
    case allow
    case deny
}

public protocol ScratchWebViewControllerDelegate: AnyObject {
    func scratchWebViewController(_ viewController: ScratchWebViewController, decidePolicyFor url: URL, isScratchEditor: Bool, decisionHandler: @escaping (WebFilterPolicy) -> Void)
    func scratchWebViewController(_ viewController: ScratchWebViewController, didDownloadFileAt url: URL)
    func scratchWebViewController(_ viewController: ScratchWebViewController, didFail error: Error)
    func scratchWebViewController(_ viewController: ScratchWebViewController, canStartScratchLinkSessionType type: SessionType) -> Bool
    func scratchWebViewController(_ viewController: ScratchWebViewController, didStartScratchLinkSessionType type: SessionType)
    func scratchWebViewController(_ viewController: ScratchWebViewController, didFailStartingScratchLinkSession type: SessionType, error: SessionError)
}

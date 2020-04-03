//
//  ViewController.swift
//  MPConnectivityTuto
//
//  Created by Rémi BARBERO on 24/03/2020.
//  Copyright © 2020 Rémi BARBERO. All rights reserved.
//

import UIKit
import MultipeerConnectivity

class ViewController: UIViewController {
    
    var mPeerId: MCPeerID!
    var mSession: MCSession!
    var mServiceAdvertiser: MCNearbyServiceAdvertiser!
    var mServiceBrowser: MCNearbyServiceBrowser!
    var messageToSend: String!
    
    @IBOutlet weak var chatView: UITextView!
    
    @IBOutlet weak var inputMessage: UITextField!
    
    //@IBOutlet weak var tapSendButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(showConnectionMenu))
        
        mPeerId = MCPeerID(displayName: UIDevice.current.name)
        mSession = MCSession(peer: mPeerId, securityIdentity: nil, encryptionPreference: .required)
        mSession.delegate = self
    }

    @objc func showConnectionMenu() {
      let ac = UIAlertController(title: "Connection Menu", message: nil, preferredStyle: .actionSheet)
      ac.addAction(UIAlertAction(title: "Host a session", style: .default, handler: hostSession))
      ac.addAction(UIAlertAction(title: "Join a session", style: .default, handler: joinSession))
      ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
      present(ac, animated: true)
    }
    
    func hostSession(action: UIAlertAction) {
        mServiceAdvertiser = MCNearbyServiceAdvertiser(peer: mPeerId, discoveryInfo: nil, serviceType: "ioscreator-chat")
        mServiceAdvertiser.delegate = self
        mServiceAdvertiser.startAdvertisingPeer()
    }

    func joinSession(action: UIAlertAction) {
        mServiceBrowser = MCNearbyServiceBrowser(peer: mPeerId, serviceType: "ioscreator-chat")
      mServiceBrowser.delegate = self
        mServiceBrowser.startBrowsingForPeers()
    }
    
    @IBAction func tapSendButton(_ sender: Any) {
        NSLog("%@", "Send button trigger");
    messageToSend = "\(mPeerId.displayName): \(inputMessage.text!)\n"
      let message = messageToSend.data(using: String.Encoding.utf8, allowLossyConversion: false)
      
      do {
        try self.mSession.send(message!, toPeers: mSession.connectedPeers, with: .unreliable)
        chatView.text = chatView.text + messageToSend
        inputMessage.text = ""
      }
      catch {
        print("Error sending message")
      }
    }
}

extension ViewController : MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        NSLog("%@", "didNotStartAdvertisingPeer: \(error)")
    }

    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        NSLog("%@", "didReceiveInvitationFromPeer \(peerID)")
        invitationHandler(true, self.mSession)
    }
}

extension ViewController : MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        NSLog("%@", "didNotStartBrowsingForPeers: \(error)")
    }

    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        NSLog("%@", "foundPeer: \(peerID)")
        NSLog("%@", "invitePeer: \(peerID)")
        browser.invitePeer(peerID, to: self.mSession, withContext: nil, timeout: 10)
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        NSLog("%@", "lostPeer: \(peerID)")
    }
}

extension ViewController : MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
      switch state {
      case .connected:
        print("Connected: \(peerID.displayName)")
      case .connecting:
        print("Connecting: \(peerID.displayName)")
      case .notConnected:
        print("Not Connected: \(peerID.displayName)")
      @unknown default:
        print("fatal error")
      }
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
         NSLog("%@", "didReceiveData: \(data)")
      DispatchQueue.main.async { [unowned self] in
        // send chat message
        let message = NSString(data: data as Data, encoding: String.Encoding.utf8.rawValue)! as String
        self.chatView.text = self.chatView.text + message
      }
    }

    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {

    }

    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {

    }

    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {

    }
}

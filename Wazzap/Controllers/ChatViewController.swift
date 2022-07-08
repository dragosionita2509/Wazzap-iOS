import UIKit
import Firebase
import FirebaseStorage
import Kingfisher

class ChatViewController: UIViewController,UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    var imagePicker = UIImagePickerController()
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var messageTextfield: UITextField!
    
    let db = Firestore.firestore()
    
    var messages: [Message] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        title = K.appName
        navigationItem.hidesBackButton = true
        
        self.tableView.register(UINib(nibName: "MessageCell", bundle: nil), forCellReuseIdentifier: "MessageCell")
        self.tableView.register(UINib(nibName: "ImageTableViewCell", bundle: nil), forCellReuseIdentifier: "ImageTableViewCell")
        
        
        
        loadMessages()
    }
    
    func loadMessages() {
        
        db.collection(K.FStore.collectionName).order(by: K.FStore.dateField).addSnapshotListener { (querySnapshot, error) in
            self.messages = []
            
            if let e = error {
                print("There was an issue retrieving the data from Firestore. \(e)")
            } else {
                if let snapshotDocuments = querySnapshot?.documents {
                    for doc in snapshotDocuments {
                        let data = doc.data()
                        if let messageSender = data[K.FStore.senderField] as? String, let messageBody = data[K.FStore.bodyField] as? String, let type = data[K.FStore.dataType] as? String {
                            let newMessage = Message(sender: messageSender, body: messageBody, type: type)
                            self.messages.append(newMessage)
                            
                            
                            DispatchQueue.main.async {
                                self.tableView.reloadData()
                                let indexPath = IndexPath(row: self.messages.count - 1, section: 0)
                                self.tableView.scrollToRow(at: indexPath, at: .top, animated: true)
                            }
                        }
                    }
                }
            }
        }
    }
    
    
    @IBAction func sendPressed(_ sender: UIButton) {
        
        if let messageBody = messageTextfield.text, let messageSender = Auth.auth().currentUser?.email {
            db.collection(K.FStore.collectionName).addDocument(data: [
                K.FStore.senderField : messageSender,
                K.FStore.bodyField: messageBody,
                K.FStore.dateField: Date().timeIntervalSince1970,
                K.FStore.dataType: "t"
            ]) {
                    (error) in
                    if let e = error {
                        print("There was an issue saving the data into firestore, \(e)")
                    } else  {
                        print("Successfully saved the data.")
                        DispatchQueue.main.async {
                            self.messageTextfield.text = ""
                        }
                    }
                }
        }
    }
    
    @IBAction func addImageAction(_ sender: UIButton) {
        
        let ImagesPickerController = UIImagePickerController()
        ImagesPickerController.allowsEditing = true
        ImagesPickerController.sourceType = .photoLibrary
        
        ImagesPickerController.delegate = self
        
        self.present(ImagesPickerController, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        
        guard let editedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage
        else {
            print("Did not get the edited image.")
            return
        }
        
        setUsersPhotoURL(withImage: editedImage)
        
        self.dismiss(animated: true, completion: nil)
        
    }
        
    func setUsersPhotoURL(withImage: UIImage) {
        guard let imageData = withImage.jpegData(compressionQuality: 0.5) else { return }
        let storageRef = Storage.storage().reference()
        let thisUserPhotoStorageRef = storageRef.child("images/").child("\(Date().currentTimeMillis()).png")

        thisUserPhotoStorageRef.putData(imageData, metadata: nil) { (metadata, error) in
            guard metadata != nil else {
                print("An error occured while uploading the image.")
                return
            }

            thisUserPhotoStorageRef.downloadURL { (url, error) in
                guard let downloadURL = url else {
                    print("An error occured after uploading the image and then getting the URL.")
                    return
                }
                
                // saving image to document
                if let messageSender = Auth.auth().currentUser?.email {
                    self.db.collection(K.FStore.collectionName).addDocument(data: [
                        K.FStore.senderField : messageSender,
                        K.FStore.bodyField: downloadURL.absoluteString,
                        K.FStore.dateField: Date().timeIntervalSince1970,
                        K.FStore.dataType: "i"
                    ]) {
                        (error) in
                        if let e = error {
                            print("There was an issue saving the data into firestore, \(e)")
                        } else  {
                            print("Successfully saved the data.")
                            DispatchQueue.main.async {
                                self.messageTextfield.text = ""
                            }
                        }
                    }
                }
                
            }
        }
    }
    
    @IBAction func logOutPressed(_ sender: UIBarButtonItem) {
        do {
            try Auth.auth().signOut()
            navigationController?.popToRootViewController(animated: true)
        } catch let signOutError as NSError {
            print("Error signing out: %@", signOutError)
        }
        
    }
}

extension ChatViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let message = messages[indexPath.row]
        
        if message.sender == Auth.auth().currentUser?.email {
            // check if message is image or text

            if message.type == "t"{
                let cell = tableView.dequeueReusableCell(withIdentifier: "MessageCell", for: indexPath)
                    as! MessageCell
                cell.label.text = message.body
                cell.leftImageView.isHidden = true
                cell.rightImageView.isHidden = false
                cell.messageBubble.backgroundColor = UIColor(named: K.BrandColors.lightPurple)
                cell.label.textColor = UIColor(named: K.BrandColors.purple)
                return cell
            }else{
                let cell = tableView.dequeueReusableCell(withIdentifier: "ImageTableViewCell", for: indexPath)
                    as! ImageTableViewCell
                cell.leftImageView.isHidden = true
                cell.rightImageView.isHidden = false
                cell.messageBubble.backgroundColor = UIColor(named: K.BrandColors.lightPurple)

                if let url = URL(string: message.body){
                    let r = ImageResource(downloadURL: url, cacheKey: message.body)
                    cell.chatImageView.kf.setImage(with: r, placeholder: UIImage(named: "cameraIcon"))
                }

                return cell
            }
        } else {

            if message.type == "t"{
                let cell = tableView.dequeueReusableCell(withIdentifier: "MessageCell", for: indexPath)
                    as! MessageCell
                cell.label.text = message.body
                cell.leftImageView.isHidden = false
                cell.rightImageView.isHidden = true
                cell.messageBubble.backgroundColor = UIColor(named: K.BrandColors.purple)
                cell.label.textColor = UIColor(named: K.BrandColors.lightPurple)
                return cell
            }else{
                let cell = tableView.dequeueReusableCell(withIdentifier: "ImageTableViewCell", for: indexPath)
                    as! ImageTableViewCell
                
                cell.leftImageView.isHidden = false
                cell.rightImageView.isHidden = true
//                cell.leftImageView.isHidden = true
//                cell.rightImageView.isHidden = false
                cell.messageBubble.backgroundColor = UIColor(named: K.BrandColors.lightPurple)

                if let url = URL(string: message.body){
                    let r = ImageResource(downloadURL: url, cacheKey: message.body)
                    cell.chatImageView.kf.setImage(with: r, placeholder: UIImage(named: "cameraIcon"))
                }

                return cell

            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if messages[indexPath.row].type != "t"{
            return 250
        }else{
            return UITableView.automaticDimension
        }
    }
}

extension ChatViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print(indexPath.row)
    }
}

extension Date {
    func currentTimeMillis() -> Int64 {
        return Int64(self.timeIntervalSince1970 * 1000)
    }
}

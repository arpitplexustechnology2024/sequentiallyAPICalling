//
//  SubCategoryViewController.swift
//  StenoappAPICalling
//
//  Created by Arpit iOS Dev. on 12/06/24.
//

import UIKit
import Alamofire

class SubCategoryViewController: UIViewController {
    
    @IBOutlet weak var subCategoryTableView: UITableView!
    @IBOutlet weak var dataListTableView: UITableView!
    @IBOutlet weak var subategoryView: UIView!
    @IBOutlet weak var dataListView: UIView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var dataListActivityIndicator: UIActivityIndicatorView!
    
    var categoryID: String!
    var subCategoryID: String!
    var subCategories = [Datum]()
    var dataList = [SubDataList]()
    var noInternetView: NoInternetView!
    var noInternetViewDataList: NoInternetView!
    var noDataView: NoDataView!
    var nodataViewDataList: NoDataView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        subCategoryTableView.delegate = self
        subCategoryTableView.dataSource = self
        subCategoryTableView.isHidden = true
        dataListTableView.delegate = self
        dataListTableView.dataSource = self
        self.dataListTableView.register(UINib(nibName: "stenoTableViewCell", bundle: nil), forCellReuseIdentifier: "stenoTableViewCell")
        self.dataListTableView.register(UINib(nibName: "DataListTableViewCell", bundle: nil), forCellReuseIdentifier: "DataListTableViewCell")
        
        setupNoInternetView()
        setupNoDataView()
        
        if let _ = categoryID {
            if isConnectedToInternet() {
                self.showLoaderAndFetchData(categoryID: self.categoryID)
            } else {
                showNoInternetView()
            }
        }
    }
    
    func setupNoInternetView() {
        noInternetView = NoInternetView()
        noInternetView.translatesAutoresizingMaskIntoConstraints = false
        noInternetView.retryButton.addTarget(self, action: #selector(retryButtonTapped), for: .touchUpInside)
        subategoryView.addSubview(noInternetView)
        
        NSLayoutConstraint.activate([
            noInternetView.leadingAnchor.constraint(equalTo: subategoryView.leadingAnchor),
            noInternetView.trailingAnchor.constraint(equalTo: subategoryView.trailingAnchor),
            noInternetView.topAnchor.constraint(equalTo: subategoryView.topAnchor),
            noInternetView.bottomAnchor.constraint(equalTo: subategoryView.bottomAnchor)
        ])
        
        noInternetView.isHidden = true
        
        noInternetViewDataList = NoInternetView()
        noInternetViewDataList.translatesAutoresizingMaskIntoConstraints = false
        noInternetViewDataList.retryButton.addTarget(self, action: #selector(retryButtonDataListTapped), for: .touchUpInside)
        dataListView.addSubview(noInternetViewDataList)
        
        NSLayoutConstraint.activate([
            noInternetViewDataList.leadingAnchor.constraint(equalTo: dataListView.leadingAnchor),
            noInternetViewDataList.trailingAnchor.constraint(equalTo: dataListView.trailingAnchor),
            noInternetViewDataList.topAnchor.constraint(equalTo: dataListView.topAnchor),
            noInternetViewDataList.bottomAnchor.constraint(equalTo: dataListView.bottomAnchor)
        ])
        
        noInternetViewDataList.isHidden = true
    }
    
    func setupNoDataView() {
        noDataView = NoDataView()
        noDataView.translatesAutoresizingMaskIntoConstraints = false
        subategoryView.addSubview(noDataView)
        
        NSLayoutConstraint.activate([
            noDataView.leadingAnchor.constraint(equalTo: subategoryView.leadingAnchor),
            noDataView.trailingAnchor.constraint(equalTo: subategoryView.trailingAnchor),
            noDataView.topAnchor.constraint(equalTo: subategoryView.topAnchor),
            noDataView.bottomAnchor.constraint(equalTo: subategoryView.bottomAnchor)
        ])
        
        noDataView.isHidden = true
        
        nodataViewDataList = NoDataView()
        nodataViewDataList.translatesAutoresizingMaskIntoConstraints = false
        dataListView.addSubview(nodataViewDataList)
        
        NSLayoutConstraint.activate([
            nodataViewDataList.leadingAnchor.constraint(equalTo: dataListView.leadingAnchor),
            nodataViewDataList.trailingAnchor.constraint(equalTo: dataListView.trailingAnchor),
            nodataViewDataList.topAnchor.constraint(equalTo: dataListView.topAnchor),
            nodataViewDataList.bottomAnchor.constraint(equalTo: dataListView.bottomAnchor)
        ])
        
        nodataViewDataList.isHidden = true
    }
    
    @objc func retryButtonTapped() {
        if isConnectedToInternet() {
            noInternetView.isHidden = true
            self.showLoaderAndFetchData(categoryID: self.categoryID)
        } else {
            showAlert(title: "No Internet", message: "Please check your internet connection and try again.")
        }
    }
    
    @objc func retryButtonDataListTapped() {
        if isConnectedToInternet() {
            noInternetViewDataList.isHidden = true
            self.fetchDocuments(categoryID: self.categoryID, subCategoryID: self.subCategoryID)
        } else {
            showAlert(title: "No Internet", message: "Please check your internet connection and try again.")
        }
    }
    
    func showLoaderAndFetchData(categoryID: String) {
        activityIndicator.startAnimating()
        activityIndicator.style = .large
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.activityIndicator.stopAnimating()
            self.subCategoryTableView.isHidden = false
            // Background thread
            DispatchQueue.global(qos: .background).async {
                self.fetchSubCategories(categoryID: self.categoryID)
            }
        }
    }
    
    func fetchSubCategories(categoryID: String) {
        let url = "http://stenoapp.gautamsteno.com/api/get_all_sub_category"
        let parameters: [String: String] = ["category_id": categoryID]
        
        AF.request(url, method: .post, parameters: parameters, encoder: URLEncodedFormParameterEncoder.default).responseJSON { response in
            switch response.result {
            case .success(let subCategoryResponse):
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: subCategoryResponse)
                    let subCategoryResponse = try JSONDecoder().decode(SubCategory.self, from: jsonData)
                    if subCategoryResponse.status == 1 && !subCategoryResponse.data.isEmpty {
                        self.subCategories = subCategoryResponse.data
                        // Update the UI on the main thread
                        DispatchQueue.main.async {
                            self.subCategoryTableView.reloadData()
                        }
                    } else {
                        // No data found
                        DispatchQueue.main.async {
                            self.showNoDataView()
                        }
                    }
                } catch {
                    // No data found
                    DispatchQueue.main.async {
                        self.showNoDataView()
                    }
                }
            case .failure(let error):
                print("Error occurred: \(error)")
            }
        }
    }
    
    func fetchDocuments(categoryID: String, subCategoryID: String) {
        let url = "http://stenoapp.gautamsteno.com/api/get_docs_list"
        let parameters: [String: String] = ["category_id": categoryID, "subcat_id": subCategoryID]
        
        AF.request(url, method: .post, parameters: parameters, encoder: URLEncodedFormParameterEncoder.default).responseJSON { response in
            switch response.result {
            case .success(let dataListResponse):
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: dataListResponse)
                    let dataListResponse = try JSONDecoder().decode(DataList.self, from: jsonData)
                    if dataListResponse.status == 1 && !dataListResponse.data.isEmpty {
                        self.dataList = dataListResponse.data
                        // Update the UI on the main thread
                        DispatchQueue.main.async {
                            self.dataListTableView.reloadData()
                        }
                    } else {
                        // No data found
                        DispatchQueue.main.async {
                            self.showNoDataViewDataLiast()
                        }
                    }
                } catch {
                    // No data found
                    DispatchQueue.main.async {
                        self.showNoDataViewDataLiast()
                    }
                }
            case .failure(let error):
                print("Error occurred: \(error)")
            }
        }
    }
    
    func showAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    func isConnectedToInternet() -> Bool {
        let networkManager = NetworkReachabilityManager()
        return networkManager?.isReachable ?? false
    }
    
    func showNoInternetView() {
        noInternetView.isHidden = false
        activityIndicator.stopAnimating()
    }
    
    func showNoInternetViewDataList() {
        noInternetViewDataList.isHidden = false
        dataListActivityIndicator.stopAnimating()
    }
    
    func showNoDataView() {
        noDataView.isHidden = false
        subCategoryTableView.isHidden = true
    }
    
    func showNoDataViewDataLiast() {
        nodataViewDataList.isHidden = false
        dataListTableView.isHidden = true
    }
}

// MARK: - TableView Dalegate & Datasource
extension SubCategoryViewController: UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == subCategoryTableView {
            return subCategories.count
        } else if tableView == dataListTableView {
            return dataList.count
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == subCategoryTableView {
            let cell = tableView.dequeueReusableCell(withIdentifier: "SubCategoryTableViewCell") as! SubCategoryTableViewCell
            let subCategory = subCategories[indexPath.row]
            cell.dataLbl.text = subCategory.name
            return cell
        } else if tableView == dataListTableView {
            if indexPath.row == 0 {
                let Cell = tableView.dequeueReusableCell(withIdentifier: "stenoTableViewCell") as! stenoTableViewCell
                return Cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "DataListTableViewCell") as! DataListTableViewCell
                if indexPath.row % 2 == 0 {
                    cell.backgroundColor = UIColor.white
                } else {
                    cell.backgroundColor = UIColor.customeGray
                }
                let datum = dataList[indexPath.row]
                cell.idLbl.text = "\(indexPath.row)"
                cell.nameLbl.text = datum.name
                switch datum.extPath {
                case .pdf:
                    cell.extPathIcon.image = UIImage(named: "pdf")
                case .mp3:
                    cell.extPathIcon.image = UIImage(named: "mp3")
                default:
                    cell.extPathIcon.image = nil
                }
                switch datum.extPath1 {
                case .pdf:
                    cell.extPath1Icon.image = UIImage(named: "pdf")
                case .mp3:
                    cell.extPath1Icon.image = UIImage(named: "mp3")
                default:
                    cell.extPath1Icon.image = nil
                }
                return cell
            }
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == subCategoryTableView {
            let selectedSubCategory = subCategories[indexPath.row]
            if let _ = categoryID {
                if isConnectedToInternet() {
                    dataListTableView.isHidden = true
                    dataListActivityIndicator.startAnimating()
                    dataListActivityIndicator.style = .large
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self.dataListActivityIndicator.stopAnimating()
                        self.dataListTableView.isHidden = false
                        DispatchQueue.global(qos: .background).async {
                            self.fetchDocuments(categoryID: self.categoryID, subCategoryID: selectedSubCategory.subCategoryID)
                        }
                    }
                } else {
                    showNoInternetViewDataList()
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if tableView == subCategoryTableView {
            return 115
        } else if tableView == dataListTableView {
            if indexPath.row == 0 {
                return 57
            } else {
                return 65
            }
        } else {
            return 0
        }
    }
}

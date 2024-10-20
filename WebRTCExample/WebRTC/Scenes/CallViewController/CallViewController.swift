//
//  CallViewController.swift
//  WebRTCExample
//
//  Created by Baran Karaoğuz on 19.10.2024.
//

import Foundation
import UIKit

final class CallViewController: UIViewController {
    
    override func loadView() {
        view = viewSource
    }
    
    private var viewModel: (any CallViewModelProtocol & LifeCycleProtocol)
    private let viewSource: CallView = CallView()
    
    init(viewModel: any CallViewModelProtocol & LifeCycleProtocol) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        observeViews()
        observeViewModel()
        super.viewDidLoad()
        viewModel.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
}

//MARK: - For Observe

extension CallViewController {
    
    func observeViews() {
        viewSource.didTapCallButtonCallback = { [weak self] in
            guard let self else { return }
            self.viewModel.didTapCallButton()
        }
        
        viewSource.didChangeTextForAliasTextFieldCallback = { [unowned self] text in
            self.viewModel.updateAlias(value: text)
        }
        
        viewSource.didChangeTextForIpAddressTextFieldCallback = { [unowned self] text in
            self.viewModel.updateRemoteIpAddress(value: text)
        }
        
        viewSource.didTapAcceptButtonCallback = { [weak self] in
            guard let self else { return }
            self.viewModel.didTapAcceptButton()
        }
        
        viewSource.didTapRejectButtonCallback = { [weak self] in
            guard let self else { return }
            self.viewModel.didTapRejectButton()
        }
        
        viewSource.meetingViewActionCallback = { [weak self] actionType in
            guard let self else { return }
            self.viewModel.didTapMeetingViewActions(type: actionType)
        }
    }
    
    func observeViewModel() {
        viewModel.observer = { [weak self] actionType in
            guard let self else { return }
            switch actionType {
            case .setPresentationModel(let model):
                viewSource.setPresentationModel(model)
            case .changeButtonState(let isEnable):
                viewSource.updateButtonState(isEnable)
            case .showReceiveCallView(let isShow, let alias, let iPAddress):
                viewSource.showReceiveCallView(isShow: isShow, ipAddress: iPAddress, alias: alias)
            case .showMeetView(let isShow, let presentationModel):
                viewSource.showMeetingView(isShow: isShow, presentationModel: presentationModel)
            }
        }
    }
    
    
}

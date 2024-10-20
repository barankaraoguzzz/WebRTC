//
//  LifeCycleProtocol.swift
//  WebRTCExample
//
//  Created by Baran Karaoğuz on 19.10.2024.
//

import Foundation

protocol LifeCycleProtocol {
    func viewDidLoad()
    func viewWillappear(_ animated: Bool)
    func viewDidappear(_ animated: Bool)
    func viewWilldisappear(_ animated: Bool)
    func viewDiddisappear(_ animated: Bool)
}

extension LifeCycleProtocol {
    func viewDidLoad() {}
    func viewWillappear(_ animated: Bool) {}
    func viewDidappear(_ animated: Bool) {}
    func viewWilldisappear(_ animated: Bool) {}
    func viewDiddisappear(_ animated: Bool) {}
}

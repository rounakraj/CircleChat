//
//  CollectionReference.swift
//  Circle
//
//  Created by Kumar Rounak on 25/06/18.
//  Copyright © 2018 Kumar Rounak. All rights reserved.
//

import Foundation
import FirebaseFirestore


enum FCollectionReference: String {
    case User
    case Typing
    case Recent
    case Message
    case Group
    case Call
}


func reference(_ collectionReference: FCollectionReference) -> CollectionReference{
    return Firestore.firestore().collection(collectionReference.rawValue)
}



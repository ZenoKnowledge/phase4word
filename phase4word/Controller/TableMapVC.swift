//
//  TableMapVC.swift
//  phase4word
//
//  Created by Yusef Nathanson on 1/19/2018.
//  Copyright © 2018 Yusef Nathanson. All rights reserved.
//

import UIKit
import MapKit
import RealmSwift

final class NoteAnnotation: NSObject, MKAnnotation {
    
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var subtitle: String?
    
    init(coordinate: CLLocationCoordinate2D, title: String?, subtitle: String?) {
        self.coordinate = coordinate
        self.title = title
        self.subtitle = subtitle
        
        super.init()
    }
    
    var region: MKCoordinateRegion {
        let span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        return MKCoordinateRegion(center: coordinate, span: span)
    }
}

class TableMapVC: UIViewController {
    
    var matchingNotes: [Note]!
    var players: Results<Addr>!

    
    var state: State!
    
//    required init? (coder aDecoder: NSCoder) {
//        state = State(game: mood, players: players)
//        super.init(coder: aDecoder)
//    }

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var mapView: MKMapView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        mapView.delegate = self
        
        
        mapView.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier)
        
        let latitude = state.currentNote?.latitude ?? state.orderedNotes[0].latitude
        let longitude = state.currentNote?.longitude ?? state.orderedNotes[0].longitude
        let data = state.currentNote?.data ?? state.orderedNotes[0].data
        let subtitle = state.currentNote?.meta ?? state.orderedNotes[0].meta
        makeAnnotation(latitude: latitude, longitude: longitude, title: data, subtitle: subtitle)
        
//        let makeShiftCoordinate = CLLocationCoordinate2D(latitude: 42.341557, longitude: -71.080943)
//        let makeShiftAnnotation = NoteAnnotation(coordinate: makeShiftCoordinate, title: "Make Shift Boston",
//                                                 subtitle: "A cooperative workspace for social justice oriented organizations and individuals")
//
//        mapView.addAnnotation(makeShiftAnnotation)
//        mapView.setRegion(makeShiftAnnotation.region, animated: true)
        
        tableView.rowHeight = UITableViewAutomaticDimension
        
        if let notes = state.notes {
            let saveState = Save(counter: state.counter, green: state.green, notes: notes, buffer: state.buffer, state: state)
            RealmService.shared.create(saveState)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
   
    
    
    
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
}

extension TableMapVC: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let noteAnnotation = mapView.dequeueReusableAnnotationView(withIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier) as? MKMarkerAnnotationView {
            noteAnnotation.animatesWhenAdded = true
            noteAnnotation.titleVisibility = .adaptive
            noteAnnotation.subtitleVisibility = .adaptive
            
            return noteAnnotation
        }
        
        return nil
    }
    
    // TODO: tap annotation to segue to viewing the note that it points to
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if let annotationTitle = view.annotation?.title {
            
            print("User tapped on annotation with title: \(annotationTitle!)")
            performSegue(withIdentifier: "mapToNote", sender: nil)
        }
    }
    
    func makeAnnotation(latitude: Double?, longitude: Double?, title: String?, subtitle: String?) {
        let coordinate = CLLocationCoordinate2D(latitude: Double(latitude!), longitude: Double(longitude!))
        let annotation = NoteAnnotation(coordinate: coordinate, title: title, subtitle: subtitle)
        mapView.addAnnotation(annotation)
        mapView.setRegion(annotation.region, animated: true)
    }
}

extension TableMapVC: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return matchingNotes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "cell") as? NoteCell else { return UITableViewCell() }
        
        
        //only show notes with matching meta
//        let predicate = NSPredicate(format: "meta == %@", (state.currentNote?.meta)!)
        print("before assignment, matchingnotes.count: \(matchingNotes.count)")
        matchingNotes = state.orderedNotes.filter({ (note) -> Bool in
            note.meta == state.currentNote?.meta
        })
        print("after assignment, matchingnotes.count: \(matchingNotes.count)")
        let note = matchingNotes[indexPath.row]
        cell.configure(with: note)
        
        return cell
    }
    
    
    func score(_ note: Note) -> Double {
        let address = note.address
        let predicate = NSPredicate(format: "address == %@", address)
        if let player = players.filter(predicate).first {
            let score = pow(Double(note.green), player.phlo)
            return score
        }
        return 0.0
    }
    
    // TODO: tap row to display note annotation. then tap annotation to segue to note
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("selected row: \(indexPath.row + 1)")
        state.currentNote = matchingNotes[indexPath.row]
        
        print(state.currentNote!)
        makeAnnotation(latitude: state.currentNote?.latitude, longitude: state.currentNote?.longitude, title: state.currentNote?.data, subtitle: state.currentNote?.meta)
        
        
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "mapToNote":
            print("map2note.state.green", state.green)
            let noteVC: NoteVC = segue.destination as! NoteVC
            noteVC.state = state
            noteVC.state.game = .MapToNote
        default:
            break
        }
        
    }
}

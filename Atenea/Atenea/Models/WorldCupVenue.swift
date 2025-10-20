//
//  WorldCupVenue.swift
//  Atenea
//
//  Created by Emilio Cruz Vargas on 10/10/25.
//

import Foundation
import MapKit
import SwiftUI

struct WorldCupMatch: Identifiable {
    let id = UUID()
    let matchNumber: Int
    let date: String
    let time: String
    let stage: String
    let teams: String
}

struct WorldCupVenue: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let city: String
    let country: String
    let coordinate: CLLocationCoordinate2D
    let primaryColor: Color
    let secondaryColor: Color
    let hexColor: String
    let colorDescription: String
    let capacity: String
    let inauguration: String
    let matches: [WorldCupMatch]
    let funFacts: [String]
    let imageName: String

    var coordinate2D: CLLocationCoordinate2D {
        coordinate
    }

    var gradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [primaryColor, secondaryColor]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var radialGradient: RadialGradient {
        RadialGradient(
            gradient: Gradient(colors: [primaryColor, secondaryColor]),
            center: .center,
            startRadius: 2,
            endRadius: 20
        )
    }

    // Conformance a Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: WorldCupVenue, rhs: WorldCupVenue) -> Bool {
        lhs.id == rhs.id
    }
}

// Todas las sedes del Mundial 2026 con sus colores característicos
extension WorldCupVenue {
    static let allVenues: [WorldCupVenue] = [
        // México
        WorldCupVenue(
            name: "Estadio Akron",
            city: "Guadalajara",
            country: "México",
            coordinate: CLLocationCoordinate2D(latitude: 20.6767, longitude: -103.3469),
            primaryColor: Color(hex: "#00A651"),
            secondaryColor: Color(hex: "#34A853"),
            hexColor: "#00A651",
            colorDescription: "Verde brillante",
            capacity: "48,071 espectadores",
            inauguration: "30 de julio de 2010",
            matches: [
                WorldCupMatch(matchNumber: 1, date: "13 de junio, 2026", time: "Por definir", stage: "Fase de Grupos", teams: "Por definir"),
                WorldCupMatch(matchNumber: 2, date: "17 de junio, 2026", time: "Por definir", stage: "Fase de Grupos", teams: "Por definir"),
                WorldCupMatch(matchNumber: 3, date: "21 de junio, 2026", time: "Por definir", stage: "Fase de Grupos", teams: "Por definir"),
                WorldCupMatch(matchNumber: 4, date: "26 de junio, 2026", time: "Por definir", stage: "Octavos de Final", teams: "Por definir")
            ],
            funFacts: [
                "Estadio con techo retráctil, uno de los más modernos de Latinoamérica",
                "Casa del Club Deportivo Guadalajara (Chivas)",
                "Primer estadio en México en contar con tecnología LED en todo el perímetro",
                "Su nombre oficial es Estadio Akron por patrocinio de la marca de neumáticos",
                "Cuenta con 52 palcos de lujo y 2,000 asientos VIP"
            ],
            imageName: "Guadalajara"
        ),
        WorldCupVenue(
            name: "Estadio Azteca",
            city: "Ciudad de México",
            country: "México",
            coordinate: CLLocationCoordinate2D(latitude: 19.3030, longitude: -99.1506),
            primaryColor: Color(hex: "#34A853"),
            secondaryColor: Color(hex: "#A14593"),
            hexColor: "#34A853 → #A14593",
            colorDescription: "Verde esmeralda a Púrpura vibrante",
            capacity: "83,264 espectadores",
            inauguration: "29 de mayo de 1966",
            matches: [
                WorldCupMatch(matchNumber: 1, date: "11 de junio, 2026", time: "Por definir", stage: "Inauguración", teams: "Por definir"),
                WorldCupMatch(matchNumber: 2, date: "15 de junio, 2026", time: "Por definir", stage: "Fase de Grupos", teams: "Por definir"),
                WorldCupMatch(matchNumber: 3, date: "19 de junio, 2026", time: "Por definir", stage: "Fase de Grupos", teams: "Por definir"),
                WorldCupMatch(matchNumber: 4, date: "23 de junio, 2026", time: "Por definir", stage: "Fase de Grupos", teams: "Por definir"),
                WorldCupMatch(matchNumber: 5, date: "28 de junio, 2026", time: "Por definir", stage: "Octavos de Final", teams: "Por definir")
            ],
            funFacts: [
                "Único estadio en el mundo que ha albergado dos finales de Copa Mundial (1970 y 1986)",
                "Diego Maradona anotó aquí el 'Gol del Siglo' y la 'Mano de Dios' en 1986",
                "Se ubica a 2,200 metros sobre el nivel del mar, afectando el rendimiento físico",
                "Durante su construcción se removieron 180 millones de kg de roca del volcán Xitle",
                "Récord de asistencia: 132,247 espectadores en la pelea Chávez vs. Haugen en 1993",
                "Apodado 'El Coloso de Santa Úrsula'",
                "Será el primer estadio en albergar partidos en tres Copas Mundiales diferentes (1970, 1986, 2026)"
            ],
            imageName: "Mexico City"
        ),
        WorldCupVenue(
            name: "Estadio BBVA",
            city: "Monterrey",
            country: "México",
            coordinate: CLLocationCoordinate2D(latitude: 25.7205, longitude: -100.2442),
            primaryColor: Color(hex: "#EF4135"),
            secondaryColor: Color(hex: "#FFEB3B"),
            hexColor: "#EF4135 → #FFEB3B",
            colorDescription: "Rojo pasión a Amarillo limón",
            capacity: "53,500 espectadores",
            inauguration: "2 de agosto de 2015",
            matches: [
                WorldCupMatch(matchNumber: 1, date: "14 de junio, 2026", time: "Por definir", stage: "Fase de Grupos", teams: "Por definir"),
                WorldCupMatch(matchNumber: 2, date: "18 de junio, 2026", time: "Por definir", stage: "Fase de Grupos", teams: "Por definir"),
                WorldCupMatch(matchNumber: 3, date: "22 de junio, 2026", time: "Por definir", stage: "Fase de Grupos", teams: "Por definir"),
                WorldCupMatch(matchNumber: 4, date: "27 de junio, 2026", time: "Por definir", stage: "Octavos de Final", teams: "Por definir")
            ],
            funFacts: [
                "Considerado uno de los estadios más modernos del continente americano",
                "Casa de los Rayados de Monterrey",
                "Primer estadio en México construido específicamente para fútbol desde cero",
                "Diseñado por los arquitectos Populous (antes HOK Sport)",
                "Cuenta con un sistema de recolección de agua pluvial de 25,000 litros",
                "Inaugurado con un partido amistoso entre Monterrey y Benfica"
            ],
            imageName: "Monterrey"
        ),

        // Estados Unidos
        WorldCupVenue(
            name: "Lumen Field",
            city: "Seattle",
            country: "USA",
            coordinate: CLLocationCoordinate2D(latitude: 47.5952, longitude: -122.3316),
            primaryColor: Color(hex: "#8BC53F"),
            secondaryColor: Color(hex: "#00573D"),
            hexColor: "#8BC53F → #00573D",
            colorDescription: "Verde lima a Verde bosque",
            capacity: "69,000 espectadores",
            inauguration: "15 de septiembre de 2002",
            matches: [
                WorldCupMatch(matchNumber: 1, date: "14 de junio, 2026", time: "Por definir", stage: "Fase de Grupos", teams: "Por definir"),
                WorldCupMatch(matchNumber: 2, date: "18 de junio, 2026", time: "Por definir", stage: "Fase de Grupos", teams: "Por definir"),
                WorldCupMatch(matchNumber: 3, date: "22 de junio, 2026", time: "Por definir", stage: "Fase de Grupos", teams: "Por definir"),
                WorldCupMatch(matchNumber: 4, date: "27 de junio, 2026", time: "Por definir", stage: "Octavos de Final", teams: "Por definir")
            ],
            funFacts: [
                "Casa de los Seattle Seahawks y Seattle Sounders FC",
                "Los aficionados de los Seahawks rompieron el récord Guinness del estadio más ruidoso con 137.6 decibeles en 2013",
                "El diseño del estadio con techos curvos amplifica el ruido y lo refleja hacia el campo",
                "Los aficionados son conocidos como el '12' (12th Man), causando frecuentes penalizaciones por salida en falso a equipos visitantes",
                "El estadio tiene un gran mástil en el extremo sur donde ondea la bandera del 12th Man",
                "Inaugurado en 2002, ha tenido varios nombres: Seahawks Stadium, Qwest Field, CenturyLink Field y ahora Lumen Field",
                "Los techos cubren el 70% de los asientos, creando un efecto acústico único"
            ],
            imageName: "Seattle"
        ),
        WorldCupVenue(
            name: "Levi's Stadium",
            city: "San Francisco Bay Area",
            country: "USA",
            coordinate: CLLocationCoordinate2D(latitude: 37.4032, longitude: -121.9700),
            primaryColor: Color(hex: "#FFC72C"),
            secondaryColor: Color(hex: "#F58220"),
            hexColor: "#FFC72C → #F58220",
            colorDescription: "Amarillo solar a Naranja encendido",
            capacity: "68,500 espectadores",
            inauguration: "17 de julio de 2014",
            matches: [
                WorldCupMatch(matchNumber: 1, date: "15 de junio, 2026", time: "Por definir", stage: "Fase de Grupos", teams: "Por definir"),
                WorldCupMatch(matchNumber: 2, date: "19 de junio, 2026", time: "Por definir", stage: "Fase de Grupos", teams: "Por definir"),
                WorldCupMatch(matchNumber: 3, date: "23 de junio, 2026", time: "Por definir", stage: "Fase de Grupos", teams: "Por definir"),
                WorldCupMatch(matchNumber: 4, date: "28 de junio, 2026", time: "Por definir", stage: "Octavos de Final", teams: "Por definir")
            ],
            funFacts: [
                "Casa de los San Francisco 49ers desde 2014",
                "Primer estadio de la NFL certificado LEED Gold por su construcción sustentable",
                "Cuenta con un techo verde de 27,000 pies cuadrados con 40 tipos diferentes de vegetación",
                "Construido por $1.3 mil millones en Santa Clara, California",
                "Fue sede del Super Bowl 50 en 2016 y será sede del Super Bowl LX en 2026",
                "Los derechos de nombre fueron comprados por Levi Strauss & Co. en 2013",
                "Tiene 8,500 asientos club y 165 suites de lujo"
            ],
            imageName: "San Francisco BAV AREA"
        ),
        WorldCupVenue(
            name: "SoFi Stadium",
            city: "Los Ángeles",
            country: "USA",
            coordinate: CLLocationCoordinate2D(latitude: 33.9535, longitude: -118.3392),
            primaryColor: Color(hex: "#FFC72C"),
            secondaryColor: Color(hex: "#EAAA00"),
            hexColor: "#FFC72C → #EAAA00",
            colorDescription: "Amarillo solar a Dorado trofeo",
            capacity: "70,240 espectadores",
            inauguration: "8 de septiembre de 2020",
            matches: [
                WorldCupMatch(matchNumber: 1, date: "16 de junio, 2026", time: "Por definir", stage: "Fase de Grupos", teams: "Por definir"),
                WorldCupMatch(matchNumber: 2, date: "20 de junio, 2026", time: "Por definir", stage: "Fase de Grupos", teams: "Por definir"),
                WorldCupMatch(matchNumber: 3, date: "24 de junio, 2026", time: "Por definir", stage: "Fase de Grupos", teams: "Por definir"),
                WorldCupMatch(matchNumber: 4, date: "29 de junio, 2026", time: "Por definir", stage: "Octavos de Final", teams: "Por definir"),
                WorldCupMatch(matchNumber: 5, date: "3 de julio, 2026", time: "Por definir", stage: "Cuartos de Final", teams: "Por definir")
            ],
            funFacts: [
                "Estadio más grande de la NFL con 3.1 millones de pies cuadrados",
                "El primer estadio cubierto-descubierto con techo translúcido de paneles ETFE",
                "Casa de los LA Rams y LA Chargers, costó aproximadamente $5.5 mil millones",
                "La Infinity Screen de Samsung tiene 70,000 pies cuadrados, la pantalla de video más grande en deportes",
                "La Infinity Screen pesa 2.2 millones de libras y tiene 80 millones de píxeles",
                "Será sede de la ceremonia de apertura y natación de los Juegos Olímpicos 2028",
                "Albergará ocho partidos del Mundial 2026 y el Super Bowl LXI en 2027"
            ],
            imageName: "Los Angeles"
        ),
        WorldCupVenue(
            name: "Arrowhead Stadium",
            city: "Kansas City",
            country: "USA",
            coordinate: CLLocationCoordinate2D(latitude: 39.0489, longitude: -94.4839),
            primaryColor: Color(hex: "#0072CE"),
            secondaryColor: Color(hex: "#00A9E0"),
            hexColor: "#0072CE → #00A9E0",
            colorDescription: "Azul real a Azul cian",
            capacity: "76,416 espectadores",
            inauguration: "12 de agosto de 1972",
            matches: [
                WorldCupMatch(matchNumber: 1, date: "17 de junio, 2026", time: "Por definir", stage: "Fase de Grupos", teams: "Por definir"),
                WorldCupMatch(matchNumber: 2, date: "21 de junio, 2026", time: "Por definir", stage: "Fase de Grupos", teams: "Por definir"),
                WorldCupMatch(matchNumber: 3, date: "25 de junio, 2026", time: "Por definir", stage: "Fase de Grupos", teams: "Por definir"),
                WorldCupMatch(matchNumber: 4, date: "30 de junio, 2026", time: "Por definir", stage: "Octavos de Final", teams: "Por definir")
            ],
            funFacts: [
                "Estadio más antiguo de la AFC, en uso desde 1972",
                "Tiene el récord mundial Guinness del estadio más ruidoso con 142.2 decibeles en 2014",
                "Cuarto estadio más grande de la NFL y el más grande del estado de Missouri",
                "Completó una renovación de $375 millones en 2010",
                "Oficialmente llamado GEHA Field at Arrowhead Stadium desde marzo de 2021",
                "Construido simultáneamente con el vecino Kauffman Stadium entre 1968 y 1972",
                "Casa de los Kansas City Chiefs, múltiples campeones del Super Bowl"
            ],
            imageName: "Kansas City"
        ),
        WorldCupVenue(
            name: "AT&T Stadium",
            city: "Dallas",
            country: "USA",
            coordinate: CLLocationCoordinate2D(latitude: 32.7473, longitude: -97.0945),
            primaryColor: Color(hex: "#662D8C"),
            secondaryColor: Color(hex: "#0A2D6C"),
            hexColor: "#662D8C → #0A2D6C",
            colorDescription: "Violeta a Azul marino profundo",
            capacity: "80,000 espectadores",
            inauguration: "27 de mayo de 2009",
            matches: [
                WorldCupMatch(matchNumber: 1, date: "18 de junio, 2026", time: "Por definir", stage: "Fase de Grupos", teams: "Por definir"),
                WorldCupMatch(matchNumber: 2, date: "22 de junio, 2026", time: "Por definir", stage: "Fase de Grupos", teams: "Por definir"),
                WorldCupMatch(matchNumber: 3, date: "26 de junio, 2026", time: "Por definir", stage: "Fase de Grupos", teams: "Por definir"),
                WorldCupMatch(matchNumber: 4, date: "1 de julio, 2026", time: "Por definir", stage: "Octavos de Final", teams: "Por definir"),
                WorldCupMatch(matchNumber: 5, date: "5 de julio, 2026", time: "Por definir", stage: "Semifinal", teams: "Por definir")
            ],
            funFacts: [
                "Casa de los Dallas Cowboys, conocido como 'Jerry's World'",
                "Construido por $1.15 mil millones, uno de los estadios más caros jamás construidos",
                "Tiene un techo retráctil y capacidad expandible a más de 100,000 espectadores",
                "Cuenta con una pantalla HD de 160 pies de largo por 71 pies de alto, una de las más grandes del mundo",
                "Fue sede del Super Bowl XLV en 2011",
                "Originalmente llamado Cowboys Stadium, renombrado AT&T Stadium en julio de 2013",
                "Alcanzó una asistencia récord de 105,121 en su primer juego de temporada regular en 2009"
            ],
            imageName: "Dallas"
        ),
        WorldCupVenue(
            name: "NRG Stadium",
            city: "Houston",
            country: "USA",
            coordinate: CLLocationCoordinate2D(latitude: 29.6847, longitude: -95.4107),
            primaryColor: Color(hex: "#FF5A00"),
            secondaryColor: Color(hex: "#F58220"),
            hexColor: "#FF5A00 → #F58220",
            colorDescription: "Naranja neón a Naranja encendido",
            capacity: "72,220 espectadores",
            inauguration: "24 de agosto de 2002",
            matches: [
                WorldCupMatch(matchNumber: 1, date: "19 de junio, 2026", time: "Por definir", stage: "Fase de Grupos", teams: "Por definir"),
                WorldCupMatch(matchNumber: 2, date: "23 de junio, 2026", time: "Por definir", stage: "Fase de Grupos", teams: "Por definir"),
                WorldCupMatch(matchNumber: 3, date: "27 de junio, 2026", time: "Por definir", stage: "Fase de Grupos", teams: "Por definir"),
                WorldCupMatch(matchNumber: 4, date: "2 de julio, 2026", time: "Por definir", stage: "Octavos de Final", teams: "Por definir")
            ],
            funFacts: [
                "Primer estadio de la NFL con techo retráctil",
                "Casa de los Houston Texans desde 2002",
                "Construido en 30 meses por un costo de $352 millones",
                "Fue sede de los Super Bowls XXXVIII (2004) y LI (2017)",
                "Originalmente llamado Reliant Stadium, renombrado NRG Stadium en 2014",
                "Albergó el Campeonato Nacional de College Football Playoff en 2024",
                "También fue sede de WrestleMania 25 en 2009"
            ],
            imageName: "Houston"
        ),
        WorldCupVenue(
            name: "Mercedes-Benz Stadium",
            city: "Atlanta",
            country: "USA",
            coordinate: CLLocationCoordinate2D(latitude: 33.7555, longitude: -84.4008),
            primaryColor: Color(hex: "#0D47A1"),
            secondaryColor: Color(hex: "#0A2D6C"),
            hexColor: "#0D47A1 → #0A2D6C",
            colorDescription: "Azul índigo a Azul marino profundo",
            capacity: "71,000 espectadores",
            inauguration: "26 de agosto de 2017",
            matches: [
                WorldCupMatch(matchNumber: 1, date: "20 de junio, 2026", time: "Por definir", stage: "Fase de Grupos", teams: "Por definir"),
                WorldCupMatch(matchNumber: 2, date: "24 de junio, 2026", time: "Por definir", stage: "Fase de Grupos", teams: "Por definir"),
                WorldCupMatch(matchNumber: 3, date: "28 de junio, 2026", time: "Por definir", stage: "Fase de Grupos", teams: "Por definir"),
                WorldCupMatch(matchNumber: 4, date: "3 de julio, 2026", time: "Por definir", stage: "Octavos de Final", teams: "Por definir"),
                WorldCupMatch(matchNumber: 5, date: "7 de julio, 2026", time: "Por definir", stage: "Semifinal", teams: "Por definir")
            ],
            funFacts: [
                "Casa de los Atlanta Falcons (NFL) y Atlanta United FC (MLS)",
                "Primer estadio en Estados Unidos con certificación LEED Platinum por construcción sustentable",
                "Construido por $1.6 mil millones, inaugurado en 2017",
                "Su techo retráctil único tiene forma de 'molinillo' con ocho paneles triangulares translúcidos",
                "Cuenta con una pantalla de 360 grados de 58 pies de altura y 1,100 pies de circunferencia",
                "Fue sede del Super Bowl LIII en 2019 y del Campeonato Nacional de College Football en 2018",
                "Será sede de partidos del Mundial 2026 y del Super Bowl LXII en 2028"
            ],
            imageName: "Atlanta"
        ),
        WorldCupVenue(
            name: "Hard Rock Stadium",
            city: "Miami",
            country: "USA",
            coordinate: CLLocationCoordinate2D(latitude: 25.9580, longitude: -80.2389),
            primaryColor: Color(hex: "#F58220"),
            secondaryColor: Color(hex: "#FF007F"),
            hexColor: "#F58220 → #FF007F",
            colorDescription: "Naranja encendido a Rosa neón",
            capacity: "65,326 espectadores",
            inauguration: "16 de agosto de 1987",
            matches: [
                WorldCupMatch(matchNumber: 1, date: "21 de junio, 2026", time: "Por definir", stage: "Fase de Grupos", teams: "Por definir"),
                WorldCupMatch(matchNumber: 2, date: "25 de junio, 2026", time: "Por definir", stage: "Fase de Grupos", teams: "Por definir"),
                WorldCupMatch(matchNumber: 3, date: "29 de junio, 2026", time: "Por definir", stage: "Fase de Grupos", teams: "Por definir"),
                WorldCupMatch(matchNumber: 4, date: "4 de julio, 2026", time: "Por definir", stage: "Tercer Lugar", teams: "Por definir")
            ],
            funFacts: [
                "Casa de los Miami Dolphins (NFL) y Miami Hurricanes (NCAA)",
                "Primer estadio multipropósito en Estados Unidos financiado completamente de forma privada",
                "Ha sido sede de seis Super Bowls (XXIII, XXIX, XXXIII, XLI, XLIV, LIV)",
                "Originalmente llamado Joe Robbie Stadium, en honor al fundador de los Dolphins",
                "También ha albergado cuatro juegos de campeonato nacional de BCS y la final de Copa América 2024",
                "Ubicado en Miami Gardens, Florida, ha pasado por múltiples renovaciones desde 1987",
                "Los derechos de nombre actuales pertenecen a Hard Rock Cafe desde 2016"
            ],
            imageName: "Miami"
        ),
        WorldCupVenue(
            name: "Lincoln Financial Field",
            city: "Filadelfia",
            country: "USA",
            coordinate: CLLocationCoordinate2D(latitude: 39.9008, longitude: -75.1675),
            primaryColor: Color(hex: "#FDB913"),
            secondaryColor: Color(hex: "#EAAA00"),
            hexColor: "#FDB913 → #EAAA00",
            colorDescription: "Amarillo dorado a Dorado trofeo",
            capacity: "67,594 espectadores",
            inauguration: "3 de agosto de 2003",
            matches: [
                WorldCupMatch(matchNumber: 1, date: "22 de junio, 2026", time: "Por definir", stage: "Fase de Grupos", teams: "Por definir"),
                WorldCupMatch(matchNumber: 2, date: "26 de junio, 2026", time: "Por definir", stage: "Fase de Grupos", teams: "Por definir"),
                WorldCupMatch(matchNumber: 3, date: "30 de junio, 2026", time: "Por definir", stage: "Fase de Grupos", teams: "Por definir"),
                WorldCupMatch(matchNumber: 4, date: "5 de julio, 2026", time: "Por definir", stage: "Cuartos de Final", teams: "Por definir")
            ],
            funFacts: [
                "Casa de los Philadelphia Eagles (NFL) y Temple Owls (NCAA)",
                "Inaugurado en 2003, reemplazando al Veterans Stadium que abrió en 1971",
                "Lincoln Financial Group pagó $139.6 millones por los derechos de nombre en junio de 2002",
                "Una renovación completada en 2014 agregó 1,600 asientos adicionales",
                "Ubicado en South Philadelphia en Pattison Avenue junto a la I-95",
                "Diseñado por las firmas de arquitectura NBBJ y Agoos Lovera Architects",
                "Los Eagles jugaron su primer juego inaugural aquí el 8 de septiembre de 2003 en Monday Night Football"
            ],
            imageName: "Philadelphia"
        ),
        WorldCupVenue(
            name: "MetLife Stadium",
            city: "Nueva York/Nueva Jersey",
            country: "USA",
            coordinate: CLLocationCoordinate2D(latitude: 40.8128, longitude: -74.0742),
            primaryColor: Color(hex: "#0A2D6C"),
            secondaryColor: Color(hex: "#0072CE"),
            hexColor: "#0A2D6C → #0072CE",
            colorDescription: "Azul marino profundo a Azul real",
            capacity: "82,500 espectadores",
            inauguration: "10 de abril de 2010",
            matches: [
                WorldCupMatch(matchNumber: 1, date: "23 de junio, 2026", time: "Por definir", stage: "Fase de Grupos", teams: "Por definir"),
                WorldCupMatch(matchNumber: 2, date: "27 de junio, 2026", time: "Por definir", stage: "Fase de Grupos", teams: "Por definir"),
                WorldCupMatch(matchNumber: 3, date: "1 de julio, 2026", time: "Por definir", stage: "Octavos de Final", teams: "Por definir"),
                WorldCupMatch(matchNumber: 4, date: "6 de julio, 2026", time: "Por definir", stage: "Cuartos de Final", teams: "Por definir"),
                WorldCupMatch(matchNumber: 5, date: "19 de julio, 2026", time: "Por definir", stage: "FINAL", teams: "Por definir")
            ],
            funFacts: [
                "Albergará la FINAL de la Copa Mundial 2026 el 19 de julio",
                "El estadio más caro construido en Estados Unidos con un costo de $1.6 mil millones",
                "Casa compartida de los New York Giants y New York Jets (NFL)",
                "El estadio más grande de la NFL por capacidad total de asientos (82,500)",
                "Ubicado en East Rutherford, Nueva Jersey, a 5 millas al oeste de la ciudad de Nueva York",
                "Uno de solo dos estadios de la NFL compartidos por dos equipos (el otro es SoFi Stadium)",
                "A diferencia de otros estadios nuevos de la NFL, MetLife Stadium no tiene techo",
                "Se están realizando extensas renovaciones para el Mundial, incluyendo la remoción de 1,740 asientos permanentes"
            ],
            imageName: "New York, New Jersey"
        ),
        WorldCupVenue(
            name: "Gillette Stadium",
            city: "Boston",
            country: "USA",
            coordinate: CLLocationCoordinate2D(latitude: 42.0909, longitude: -71.2643),
            primaryColor: Color(hex: "#EAAA00"),
            secondaryColor: Color(hex: "#FFC72C"),
            hexColor: "#EAAA00 → #FFC72C",
            colorDescription: "Dorado trofeo a Amarillo solar",
            capacity: "64,628 espectadores",
            inauguration: "11 de mayo de 2002",
            matches: [
                WorldCupMatch(matchNumber: 1, date: "24 de junio, 2026", time: "Por definir", stage: "Fase de Grupos", teams: "Por definir"),
                WorldCupMatch(matchNumber: 2, date: "28 de junio, 2026", time: "Por definir", stage: "Fase de Grupos", teams: "Por definir"),
                WorldCupMatch(matchNumber: 3, date: "2 de julio, 2026", time: "Por definir", stage: "Octavos de Final", teams: "Por definir"),
                WorldCupMatch(matchNumber: 4, date: "7 de julio, 2026", time: "Por definir", stage: "Cuartos de Final", teams: "Por definir")
            ],
            funFacts: [
                "Casa de los New England Patriots (NFL) y New England Revolution (MLS)",
                "Inaugurado en 2002, reemplazando al adyacente Foxboro Stadium",
                "Todo el costo de construcción de $325 millones fue financiado de forma privada",
                "Ubicado en Foxborough, Massachusetts, a 22 millas al suroeste de Boston",
                "Incluye 5,876 asientos club y 82 suites de lujo",
                "Durante el Mundial 2026, será conocido como 'Boston Stadium' por las reglas de patrocinio de FIFA",
                "Los Patriots jugaron su primer juego aquí el 9 de septiembre de 2002"
            ],
            imageName: "Boston"
        ),

        // Canadá
        WorldCupVenue(
            name: "BC Place",
            city: "Vancouver",
            country: "Canadá",
            coordinate: CLLocationCoordinate2D(latitude: 49.2768, longitude: -123.1119),
            primaryColor: Color(hex: "#00573D"),
            secondaryColor: Color(hex: "#EC008C"),
            hexColor: "#00573D → #EC008C",
            colorDescription: "Verde bosque a Rosa magenta",
            capacity: "54,500 espectadores",
            inauguration: "19 de junio de 1983",
            matches: [
                WorldCupMatch(matchNumber: 1, date: "13 de junio, 2026", time: "Por definir", stage: "Fase de Grupos", teams: "Por definir"),
                WorldCupMatch(matchNumber: 2, date: "17 de junio, 2026", time: "Por definir", stage: "Fase de Grupos", teams: "Por definir"),
                WorldCupMatch(matchNumber: 3, date: "21 de junio, 2026", time: "Por definir", stage: "Fase de Grupos", teams: "Por definir"),
                WorldCupMatch(matchNumber: 4, date: "25 de junio, 2026", time: "Por definir", stage: "Fase de Grupos", teams: "Por definir"),
                WorldCupMatch(matchNumber: 5, date: "30 de junio, 2026", time: "Por definir", stage: "Octavos de Final", teams: "Por definir")
            ],
            funFacts: [
                "Casa de los BC Lions (CFL) y Vancouver Whitecaps FC (MLS)",
                "Inaugurado en 1983, originalmente con el techo inflable más grande del mundo",
                "Cerrado por 16 meses después de los Juegos Olímpicos de Invierno 2010 para una renovación extensa",
                "El techo inflable fue reemplazado por un techo retráctil soportado por cables en 2011",
                "Récord de asistencia de 65,061 personas en un concierto de Ed Sheeran el 2 de septiembre de 2023",
                "Capacidad puede expandirse a más de 65,000 para eventos especiales con asientos en el piso",
                "También alberga el BC Sports Hall of Fame y el torneo anual Canada Sevens de rugby"
            ],
            imageName: "Vancouver"
        ),
        WorldCupVenue(
            name: "BMO Field",
            city: "Toronto",
            country: "Canadá",
            coordinate: CLLocationCoordinate2D(latitude: 43.6332, longitude: -79.4189),
            primaryColor: Color(hex: "#00A9E0"),
            secondaryColor: Color(hex: "#E41E26"),
            hexColor: "#00A9E0 → #E41E26",
            colorDescription: "Azul cian a Rojo carmesí",
            capacity: "30,991 espectadores",
            inauguration: "28 de abril de 2007",
            matches: [
                WorldCupMatch(matchNumber: 1, date: "12 de junio, 2026", time: "Por definir", stage: "Inauguración de Canadá", teams: "Canadá vs. Por definir"),
                WorldCupMatch(matchNumber: 2, date: "16 de junio, 2026", time: "Por definir", stage: "Fase de Grupos", teams: "Por definir"),
                WorldCupMatch(matchNumber: 3, date: "20 de junio, 2026", time: "Por definir", stage: "Fase de Grupos", teams: "Por definir"),
                WorldCupMatch(matchNumber: 4, date: "24 de junio, 2026", time: "Por definir", stage: "Fase de Grupos", teams: "Por definir"),
                WorldCupMatch(matchNumber: 5, date: "29 de junio, 2026", time: "Por definir", stage: "Octavos de Final", teams: "Por definir")
            ],
            funFacts: [
                "Albergará el partido inaugural de Canadá el 12 de junio de 2026",
                "Casa de Toronto FC (MLS) y Toronto Argonauts (CFL)",
                "Ubicado en Exhibition Place en Toronto, Ontario",
                "Construido originalmente como estadio específico de fútbol para la Copa Mundial Sub-20 de 2007",
                "Inaugurado en 2007 con capacidad de 25,000, expandida posteriormente a más de 30,000",
                "Para el Mundial 2026, se agregarán 17,756 asientos temporales para alcanzar capacidad de 45,736",
                "Nombrado en honor a Bank of Montreal (BMO), uno de los principales bancos de Canadá"
            ],
            imageName: "Toronto"
        )
    ]
}

// Extension para crear Color desde hex
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}



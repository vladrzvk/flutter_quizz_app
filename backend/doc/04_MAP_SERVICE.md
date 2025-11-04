# 🗺️ Service de Cartes - Architecture Complète

Service de cartes interactives réutilisable et interopérable.

## 📋 Table des Matières

1. [Vision & Objectifs](#vision--objectifs)
2. [Architecture](#architecture)
3. [Technologies](#technologies)
4. [API Design](#api-design)
5. [Base de Données](#base-de-données)
6. [Frontend Integration](#frontend-integration)
7. [Interopérabilité](#interopérabilité)
8. [Performance](#performance)

---

## 🎯 Vision & Objectifs

### Vision

**Créer un service de cartes autonome, réutilisable et interopérable** qui peut :
- 🗺️ Afficher des cartes interactives (tuiles vectorielles)
- 📍 Gérer des collections géographiques (pays, régions, villes)
- ✅ Valider des clics sur la carte
- 🔌 S'intégrer dans n'importe quelle application
- 🌍 Être consommé par web, mobile, desktop

### Objectifs

1. **Réutilisabilité** : Un seul service pour tous les projets
2. **Interopérabilité** : API REST + GraphQL + WebSocket
3. **Performance** : Cartes vectorielles + cache Redis
4. **Scalabilité** : Stateless, horizontalement scalable
5. **Extensibilité** : Facile d'ajouter de nouvelles cartes

---

## 🏗️ Architecture

### Architecture Globale┌────────────────────────────────────────────────────────┐
│                    MAP SERVICE                          │
├────────────────────────────────────────────────────────┤
│                                                         │
│  ┌──────────────────────────────────────────────┐    │
│  │           API Layer                          │    │
│  ├──────────────────────────────────────────────┤    │
│  │  🔌 REST API        (CRUD)                   │    │
│  │  🔷 GraphQL API     (Queries + Subscriptions)│    │
│  │  ⚡ WebSocket       (Real-time)              │    │
│  │  📡 gRPC            (Inter-service)          │    │
│  └──────────────────────────────────────────────┘    │
│                         │                              │
│  ┌──────────────────────▼──────────────────────┐    │
│  │         Business Logic                      │    │
│  ├──────────────────────────────────────────────┤    │
│  │  🗺️  Map Manager                            │    │
│  │  📦 Collection Manager                       │    │
│  │  ✅ Validation Engine                        │    │
│  │  🎨 Style Manager                            │    │
│  │  📍 Geocoding Service                        │    │
│  └──────────────────────────────────────────────┘    │
│                         │                              │
│  ┌──────────────────────▼──────────────────────┐    │
│  │         Data Layer                          │    │
│  ├──────────────────────────────────────────────┤    │
│  │  🗄️  PostGIS (Géométries)                   │    │
│  │  🚀 Redis (Cache)                            │    │
│  │  📦 S3 (Tiles storage)                       │    │
│  └──────────────────────────────────────────────┘    │
│                                                         │
└────────────────────────────────────────────────────────┘
│                          │
▼                          ▼
┌──────────────┐          ┌──────────────┐
│  Quiz App    │          │  Other Apps  │
│  (Flutter)   │          │  (Web/Mobile)│
└──────────────┘          └──────────────┘

### Microservice Pattern┌─────────────────────────────────────────────────┐
│           Service Mesh (Istio)                  │
├─────────────────────────────────────────────────┤
│                                                 │
│  ┌──────────────┐      ┌──────────────┐       │
│  │ Quiz Backend │◀────▶│ Map Service  │       │
│  └──────────────┘      └──────────────┘       │
│         │                      │                │
│         │              ┌───────▼─────────┐     │
│         │              │   PostGIS DB    │     │
│         │              └─────────────────┘     │
│         │                                       │
│  ┌──────▼──────┐                               │
│  │ PostgreSQL  │                               │
│  └─────────────┘                               │
│                                                 │
└─────────────────────────────────────────────────┘

---

## 🛠️ Technologies

### Stack Technique

#### BackendOption A : Rust (Recommandé - Performance)
├─ Axum (Web framework)
├─ PostGIS (via SQLx)
├─ Redis (via redis-rs)
└─ Tokio (Async runtime)Option B : Node.js (Rapidité de dev)
├─ Express/Fastify
├─ PostGIS (via node-postgres)
├─ Redis (via ioredis)
└─ TypeScript

#### Base de DonnéesPostgreSQL 15+ avec extensions :
├─ PostGIS (géométries)
├─ pg_trgm (recherche full-text)
└─ pg_stat_statements (performance)

#### CacheRedis 7+
├─ Tiles cache
├─ Collections cache
└─ Session management

#### FrontendFlutter (Mobile/Web)
├─ flutter_map (Leaflet-based)
├─ maplibre_gl (Mapbox-based)
└─ Custom painting (Canvas)Web (Bonus)
├─ Leaflet.js
├─ Mapbox GL JS
└─ OpenLayers

---

## 🔌 API Design

### REST API

#### Collections
```httpLister toutes les collections
GET /api/v1/maps/collections
Response: 200 OK
[
{
"id": "france-regions",
"name": "Régions de France",
"description": "13 régions métropolitaines",
"type": "polygons",
"feature_count": 13,
"bbox": [-5.142, 41.333, 9.560, 51.089]
}
]Récupérer une collection
GET /api/v1/maps/collections/{id}
Response: 200 OK
{
"id": "france-regions",
"name": "Régions de France",
"geojson": {
"type": "FeatureCollection",
"features": [...]
}
}Créer une collection
POST /api/v1/maps/collections
Content-Type: application/json
{
"name": "Départements",
"type": "polygons",
"geojson": {...}
}
Response: 201 Created

#### Features (Entités géographiques)
```httpRécupérer une feature
GET /api/v1/maps/features/{id}
Response: 200 OK
{
"id": "region-idf",
"name": "Île-de-France",
"properties": {
"code": "11",
"population": 12278210,
"superficie": 12011
},
"geometry": {
"type": "Polygon",
"coordinates": [[[2.22, 48.81], ...]]
}
}Rechercher des features
GET /api/v1/maps/features/search?q=paris&collection=france-cities
Response: 200 OK
[
{
"id": "city-paris",
"name": "Paris",
"geometry": {...}
}
]

#### Validation
```httpValider un clic sur la carte
POST /api/v1/maps/validate-click
Content-Type: application/json
{
"collection_id": "france-regions",
"coordinates": [2.3522, 48.8566],
"target_feature_id": "region-idf"
}
Response: 200 OK
{
"is_valid": true,
"clicked_feature": {
"id": "region-idf",
"name": "Île-de-France"
},
"distance_meters": 0
}

#### Tiles (Tuiles vectorielles)
```httpRécupérer une tuile vectorielle
GET /api/v1/maps/tiles/{collection}/{z}/{x}/{y}.pbf
Response: 200 OK
Content-Type: application/x-protobuf
<binary data>Style de carte
GET /api/v1/maps/styles/{style_id}
Response: 200 OK
{
"version": 8,
"sources": {...},
"layers": [...]
}

---

### GraphQL API

**Schema** : `schema.graphql`
```graphqltype Query {
Collections
collections: [Collection!]!
collection(id: ID!): CollectionFeatures
feature(id: ID!): Feature
searchFeatures(query: String!, collectionId: ID): [Feature!]!Validation
validateClick(input: ValidateClickInput!): ValidationResult!Geocoding
geocode(address: String!): [GeocodingResult!]!
reverseGeocode(lat: Float!, lon: Float!): GeocodingResult
}type Mutation {
Collections
createCollection(input: CreateCollectionInput!): Collection!
updateCollection(id: ID!, input: UpdateCollectionInput!): Collection!
deleteCollection(id: ID!): Boolean!
}type Subscription {
Real-time updates
featureUpdated(collectionId: ID!): Feature!
}type Collection {
id: ID!
name: String!
description: String
type: CollectionType!
features: [Feature!]!
bbox: BoundingBox!
featureCount: Int!
createdAt: DateTime!
updatedAt: DateTime!
}type Feature {
id: ID!
name: String!
properties: JSON!
geometry: Geometry!
collection: Collection!
}type Geometry {
type: GeometryType!
coordinates: JSON!
}enum GeometryType {
POINT
LINE_STRING
POLYGON
MULTI_POINT
MULTI_LINE_STRING
MULTI_POLYGON
}enum CollectionType {
POINTS
LINES
POLYGONS
MIXED
}type BoundingBox {
minLon: Float!
minLat: Float!
maxLon: Float!
maxLat: Float!
}input ValidateClickInput {
collectionId: ID!
coordinates: [Float!]!
targetFeatureId: ID
}type ValidationResult {
isValid: Boolean!
clickedFeature: Feature
distanceMeters: Float
}type GeocodingResult {
address: String!
coordinates: [Float!]!
relevance: Float!
}scalar DateTime
scalar JSON

---

### WebSocket API
```javascript// Connexion WebSocket
const ws = new WebSocket('ws://map-service/ws');// Écouter les mises à jour
ws.send(JSON.stringify({
type: 'subscribe',
collection: 'france-regions'
}));ws.onmessage = (event) => {
const data = JSON.parse(event.data);
console.log('Feature updated:', data);
};

---

## 💾 Base de Données

### Schéma PostGIS
```sql-- Extension PostGIS
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS postgis_topology;-- Table des collections
CREATE TABLE map_collections (
id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
name VARCHAR(255) NOT NULL,
slug VARCHAR(255) UNIQUE NOT NULL,
description TEXT,
type VARCHAR(50) NOT NULL CHECK (type IN ('points', 'lines', 'polygons', 'mixed')),
bbox GEOMETRY(Polygon, 4326),
feature_count INTEGER DEFAULT 0,
metadata JSONB DEFAULT '{}',
is_active BOOLEAN DEFAULT true,
created_at TIMESTAMPTZ DEFAULT NOW(),
updated_at TIMESTAMPTZ DEFAULT NOW()
);-- Table des features
CREATE TABLE map_features (
id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
collection_id UUID NOT NULL REFERENCES map_collections(id) ON DELETE CASCADE,
name VARCHAR(255) NOT NULL,
properties JSONB NOT NULL DEFAULT '{}',
geometry GEOMETRY(Geometry, 4326) NOT NULL,
centroid GEOMETRY(Point, 4326),
created_at TIMESTAMPTZ DEFAULT NOW(),
updated_at TIMESTAMPTZ DEFAULT NOW()
);-- Index spatiaux (CRUCIAL pour la performance)
CREATE INDEX idx_features_geometry ON map_features USING GIST(geometry);
CREATE INDEX idx_features_centroid ON map_features USING GIST(centroid);
CREATE INDEX idx_collections_bbox ON map_collections USING GIST(bbox);-- Index full-text search
CREATE INDEX idx_features_name_trgm ON map_features USING GIN(name gin_trgm_ops);-- Index JSONB
CREATE INDEX idx_features_properties ON map_features USING GIN(properties);-- Fonction pour calculer le centroid automatiquement
CREATE OR REPLACE FUNCTION update_feature_centroid()
RETURNS TRIGGER AS $$
BEGIN
NEW.centroid = ST_Centroid(NEW.geometry);
RETURN NEW;
END;
$$ LANGUAGE plpgsql;-- Trigger pour le centroid
CREATE TRIGGER feature_centroid_trigger
BEFORE INSERT OR UPDATE ON map_features
FOR EACH ROW
EXECUTE FUNCTION update_feature_centroid();-- Fonction pour mettre à jour le feature_count
CREATE OR REPLACE FUNCTION update_collection_feature_count()
RETURNS TRIGGER AS $$
BEGIN
IF TG_OP = 'INSERT' THEN
UPDATE map_collections
SET feature_count = feature_count + 1
WHERE id = NEW.collection_id;
ELSIF TG_OP = 'DELETE' THEN
UPDATE map_collections
SET feature_count = feature_count - 1
WHERE id = OLD.collection_id;
END IF;
RETURN NULL;
END;
$$ LANGUAGE plpgsql;-- Trigger pour le count
CREATE TRIGGER collection_feature_count_trigger
AFTER INSERT OR DELETE ON map_features
FOR EACH ROW
EXECUTE FUNCTION update_collection_feature_count();-- Vue pour les GeoJSON complets
CREATE OR REPLACE VIEW map_collections_geojson AS
SELECT
c.id,
c.name,
c.slug,
jsonb_build_object(
'type', 'FeatureCollection',
'features', jsonb_agg(
jsonb_build_object(
'type', 'Feature',
'id', f.id,
'properties', jsonb_build_object(
'name', f.name
) || f.properties,
'geometry', ST_AsGeoJSON(f.geometry)::jsonb
)
)
) as geojson
FROM map_collections c
LEFT JOIN map_features f ON c.id = f.collection_id
GROUP BY c.id, c.name, c.slug;

### Seed Data : Régions de France

**Fichier** : `migrations/seeds/map_france_regions.sql`
```sql-- Insérer la collection
INSERT INTO map_collections (id, name, slug, type, description)
VALUES (
'00000000-0000-0000-0000-000000000001',
'Régions de France',
'france-regions',
'polygons',
'13 régions métropolitaines de France'
);-- Insérer les régions (exemple avec Île-de-France)
INSERT INTO map_features (collection_id, name, properties, geometry)
VALUES (
'00000000-0000-0000-0000-000000000001',
'Île-de-France',
'{"code": "11", "population": 12278210, "capitale": "Paris"}',
ST_GeomFromGeoJSON('{
"type": "Polygon",
"coordinates": [[
[1.446, 49.241],
[3.558, 49.241],
[3.558, 48.120],
[1.446, 48.120],
[1.446, 49.241]
]]
}')
);-- Ajouter toutes les autres régions...
-- (13 régions au total)

---

## 📱 Frontend Integration

### Flutter Widget Réutilisable

**Fichier** : `lib/shared/widgets/interactive_map_widget.dart`
```dartimport 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';class InteractiveMapWidget extends StatefulWidget {
final String collectionId;
final Function(String featureId, LatLng coordinates)? onTap;
final bool enableSelection;const InteractiveMapWidget({
super.key,
required this.collectionId,
this.onTap,
this.enableSelection = true,
});@override
State<InteractiveMapWidget> createState() => _InteractiveMapWidgetState();
}class _InteractiveMapWidgetState extends State<InteractiveMapWidget> {
final MapController _mapController = MapController();
List<Polygon> _polygons = [];
String? _selectedFeatureId;@override
void initState() {
super.initState();
_loadCollection();
}Future<void> _loadCollection() async {
// Charger les features depuis l'API
final response = await mapService.getCollection(widget.collectionId);setState(() {
  _polygons = response.features.map((feature) {
    return Polygon(
      points: _parseCoordinates(feature.geometry.coordinates),
      color: Colors.blue.withOpacity(0.2),
      borderColor: Colors.blue,
      borderStrokeWidth: 2,
    );
  }).toList();
});
}void _handleTap(LatLng coordinates) async {
if (!widget.enableSelection) return;// Valider le clic via l'API
final result = await mapService.validateClick(
  collectionId: widget.collectionId,
  coordinates: coordinates,
);if (result.isValid) {
  setState(() {
    _selectedFeatureId = result.clickedFeature.id;
  });  widget.onTap?.call(result.clickedFeature.id, coordinates);
}
}@override
Widget build(BuildContext context) {
return FlutterMap(
mapController: _mapController,
options: MapOptions(
center: LatLng(46.603354, 1.888334), // Centre de la France
zoom: 6,
onTap: (tapPosition, latLng) => _handleTap(latLng),
),
children: [
TileLayer(
urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
userAgentPackageName: 'com.example.quiz_geo_app',
),
PolygonLayer(
polygons: _polygons,
),
if (_selectedFeatureId != null)
MarkerLayer(
markers: [
// Afficher un marker sur la feature sélectionnée
],
),
],
);
}
}

### Usage dans l'App
```dart// Dans une question de quiz
InteractiveMapWidget(
collectionId: 'france-regions',
onTap: (featureId, coordinates) {
print('Feature cliquée : $featureId');
// Soumettre la réponse
quizBloc.add(SubmitAnswerEvent(
answer: featureId,
));
},
)

---

## 🔗 Interopérabilité

### Package NPM (JavaScript/TypeScript)
```typescript// @quiz-geo/map-clientimport { MapClient } from '@quiz-geo/map-client';const client = new MapClient({
baseUrl: 'https://map-service.example.com',
apiKey: 'your-api-key',
});// Charger une collection
const collection = await client.getCollection('france-regions');// Valider un clic
const result = await client.validateClick({
collectionId: 'france-regions',
coordinates: [2.3522, 48.8566],
targetFeatureId: 'region-idf',
});console.log(result.isValid); // true

### Package Pub (Dart/Flutter)
```dart// map_service_clientimport 'package:map_service_client/map_service_client.dart';final client = MapServiceClient(
baseUrl: 'https://map-service.example.com',
);// Charger une collection
final collection = await client.getCollection('france-regions');// Valider un clic
final result = await client.validateClick(
collectionId: 'france-regions',
coordinates: LatLng(48.8566, 2.3522),
);print(result.isValid); // true

### API REST directe (cURL)
```bashRécupérer une collection
curl https://map-service.example.com/api/v1/maps/collections/france-regionsValider un clic
curl -X POST https://map-service.example.com/api/v1/maps/validate-click 
-H "Content-Type: application/json" 
-d '{
"collection_id": "france-regions",
"coordinates": [2.3522, 48.8566]
}'

---

## ⚡ Performance

### Stratégie de Cache
Collections (Redis) : TTL 1 heure
Features (Redis) : TTL 30 minutes
Tiles (CDN) : Cache forever
Validation (In-memory) : TTL 5 minutes


### Optimisations PostGIS
```sql-- 1. Index spatiaux (déjà fait)
CREATE INDEX idx_features_geometry ON map_features USING GIST(geometry);-- 2. Simplifier les géométries pour le zoom out
CREATE MATERIALIZED VIEW map_features_simplified AS
SELECT
id,
collection_id,
name,
ST_Simplify(geometry, 0.01) as geometry
FROM map_features;-- 3. Pré-calculer les bounding boxes
UPDATE map_features
SET properties = properties || jsonb_build_object(
'bbox', ST_AsGeoJSON(ST_Envelope(geometry))::jsonb
);

### Benchmarks Attendus

| Opération | Temps (p95) | RPS |
|-----------|-------------|-----|
| GET collection | < 50ms | 1000+ |
| Validate click | < 20ms | 2000+ |
| Search features | < 30ms | 1500+ |
| Get tile | < 10ms | 5000+ |

---

## 📚 Ressources

- [PostGIS Documentation](https://postgis.net/docs/)
- [GeoJSON Specification](https://geojson.org/)
- [Mapbox Vector Tiles](https://docs.mapbox.com/data/tilesets/guides/vector-tiles-introduction/)
- [Flutter Map Package](https://pub.dev/packages/flutter_map)
- [OpenStreetMap](https://www.openstreetmap.org/)
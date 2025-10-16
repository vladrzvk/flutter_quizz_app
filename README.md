# flutter_geo_app
geo_app_quizz

1.1 Objectifs

Développer une plateforme de quiz géographique évolutive avec quatre versions progressives :

V0 : Quiz textuel sur la géographie française

V1 : Quiz avec carte interactive sur la France

V2 : Extension à l'Europe (mode texte)

V3 : Quiz Europe avec carte interactive

1.2 Contraintes Principales

Réutilisabilité : Le microservice Carte doit être totalement agnostique et réutilisable pour d'autres applications (ex: application de randonnée en React)

Scalabilité : Architecture capable de supporter l'ajout de nouvelles régions géographiques

Interopérabilité : Standards ouverts (GeoJSON, OpenAPI) pour faciliter l'intégration

Performance : Temps de réponse < 200ms pour les requêtes standards, < 1s pour les opérations spatiales complexes

Clean Architecture : Application Flutter avec séparation stricte des couches pour maintenabilité et testabilité

1.3 Stack Technologique

Couche Technologies 
Frontend MobileFlutter 3.16+,Dart 3.2+ 
Architecture Mobile Clean Architecture (Domain/Data/Presentation) 
State ManagementBloc 8.1+ / Freezed / Injectable
Cartographie flutter_map 6.0+, Mapbox GL

Backend Services Rust 1.75+, Axum 0.7+, sqlx 0.7+
Base de Données PostgreSQL 15+, PostGIS 3.3+CacheRedis 7+
Conteneurisation Docker 24+
Orchestration Kubernetes 1.28+
IaC Terraform 1.5+
CI/CDGitHub Actions, Codemagic
Monitoring Prometheus, Grafana, Loki


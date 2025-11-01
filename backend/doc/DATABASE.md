DATABASE.mdmarkdown# 🗄️ Base de Données

Documentation complète du schéma de base de données PostgreSQL.

## 📋 Vue d'Ensemble

Le système utilise **PostgreSQL 15+** avec les extensions suivantes :

- `uuid-ossp` - Génération d'UUIDs
- `pg_trgm` - Recherche full-text (V1)
- `postgis` - Données géospatiales (V1, optionnel)

---

## 🏗️ Schéma Complet

### Diagramme ERD
┌─────────────┐
│   domains   │
└──────┬──────┘
│
│ 1:N
▼
┌─────────────┐         ┌──────────────┐
│   quizzes   │────────▶│  questions   │
└──────┬──────┘   1:N   └──────┬───────┘
│                        │
│ 1:N                    │ 1:N
▼                        ▼
┌─────────────────┐      ┌─────────────┐
│ sessions_quiz   │      │  reponses   │
└────────┬────────┘      └─────────────┘
│
│ 1:N
▼
┌──────────────────────┐
│ reponses_utilisateur │
└──────────────────────┘



### Analyse de Performance
```sql
-- Voir les requêtes lentes
SELECT * FROM pg_stat_statements 
ORDER BY total_exec_time DESC 
LIMIT 10;

-- Analyser une requête
EXPLAIN ANALYZE
SELECT * FROM questions WHERE quiz_id = '...';
```

---

## 🔧 Maintenance

### Backup
```bash
# Backup complet
docker exec backend-postgres-quiz-1 pg_dump -U quiz_user quiz_db > backup.sql

# Backup avec compression
docker exec backend-postgres-quiz-1 pg_dump -U quiz_user quiz_db | gzip > backup.sql.gz
```

### Restore
```bash
# Restore
docker exec -i backend-postgres-quiz-1 psql -U quiz_user -d quiz_db < backup.sql

# Restore avec compression
gunzip -c backup.sql.gz | docker exec -i backend-postgres-quiz-1 psql -U quiz_user -d quiz_db
```

### Vacuum
```sql
-- Nettoyer et analyser
VACUUM ANALYZE;

-- Vacuum complet (bloque les tables)
VACUUM FULL;
```

---

## 📚 Ressources

- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [SQLx Documentation](https://docs.rs/sqlx/)
- [Migrations Guide](SETUP.md#5-migrations-de-la-base-de-données)

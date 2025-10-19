


# Ajouter des méthodes personnalisées tout en gardant la génération automatique de freezed :

### 🔧 Méthode 1 : Avec Private Constructor (Recommandé)
C'est la méthode officielle Freezed pour ajouter des méthodes custom.

exemple:
import 'package:freezed_annotation/freezed_annotation.dart';

part 'question_model.freezed.dart';
part 'question_model.g.dart';

@freezed
class QuestionModel with _$QuestionModel {

// ⚠️ Important : Ajouter ce constructor privé
const QuestionModel._();

const factory QuestionModel({
required String id,
@JsonKey(name: 'quiz_id') required String quizId,
required int ordre,
@JsonKey(name: 'type_question') required String typeQuestion,
@JsonKey(name: 'question_data') required Map<String, dynamic> questionData,
required int points,
@JsonKey(name: 'temps_limite_sec') int? tempsLimiteSec,
String? hint,
String? explanation,
}) = _QuestionModel;

factory QuestionModel.fromJson(Map<String, dynamic> json) =>
_$QuestionModelFromJson(json);

// 🎯 TES MÉTHODES PERSONNALISÉES ICI

/// Récupère le texte de la question depuis question_data
String get questionText {
return questionData['text'] as String? ?? '';
}

/// Récupère les options de réponse
List<String> get options {
final opts = questionData['options'];
if (opts is List) {
return opts.cast<String>();
}
return [];
}

/// Vérifie si la question a des options
bool get hasOptions => options.isNotEmpty;

/// Durée formatée
String get formattedDuration {
if (tempsLimiteSec == null) return 'Pas de limite';
final minutes = tempsLimiteSec! ~/ 60;
final seconds = tempsLimiteSec! % 60;
if (minutes > 0) {
return '${minutes}min ${seconds}s';
}
return '${seconds}s';
}
}

### 🔧 Méthode 2 : Extension Methods (Alternative)
Si tu préfères séparer complètement la logique, tu peux utiliser des extensions :
// question_model.dart (juste la définition Freezed)

@freezed
class QuestionModel with _$QuestionModel {
const factory QuestionModel({...}) = _QuestionModel;
factory QuestionModel.fromJson(Map<String, dynamic> json) => ...;
}

// question_extensions.dart (méthodes séparées)
extension QuestionModelExtensions on QuestionModel {
String get questionText {
return questionData['text'] as String? ?? '';
}

List<String> get options {
final opts = questionData['options'];
if (opts is List) {
return opts.cast<String>();
}
return [];
}
}

### ⚠️ Points Importants
1. Le constructor privé est ESSENTIEL 
2. Ordre des déclarations (1. Constructor privé d'abord => 2. Factory ensuite => 3. fromJson => 4. Tes méthodes à la fin )
3. Pas d'état mutable :
   // ❌ INTERDIT avec Freezed
   int _counter = 0;
   void increment() => _counter++;

// ✅ OK - Méthodes qui retournent des valeurs
int get doubled => points * 2;
String get formattedText => '...';
bool get isValid => points > 0;

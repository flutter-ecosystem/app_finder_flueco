# App Finder Flueco

Prototype Flutter/Flueco d'une app Android qui liste les applications installées et permet de rechercher par nom, package, catégorie ou utilité.

## Installation

```bash
flutter pub get
flutter run
```

## Notes importantes

- Ciblage principal : Android.
- `installed_apps` nécessite `QUERY_ALL_PACKAGES` pour voir toutes les apps sur Android 11+.
- Pour une publication Play Store, créer un flavor sans cette permission ou justifier l'usage.
- La recherche IA n'est pas obligatoire pour le MVP : le moteur actuel utilise scoring + synonymes + catégories Android + tags heuristiques.

## Extension IA possible

Ajouter un service `AppCategoryEnricher` qui reçoit `{name, packageName, category}` et renvoie des tags comme `musique`, `finance`, `navigation`, etc. Il faut ensuite cacher ces tags localement avec Hive/SharedPreferences via Flueco.

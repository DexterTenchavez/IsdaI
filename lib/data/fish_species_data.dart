/// The six fish species IsdaAI supports (SRS FR-08, FR-32).
/// Used by the species picker on the camera screen and by Fish Info & Guide.
///
/// To add a photo for a species, put the image in assets/fish/ (declare the
/// folder in pubspec.yaml) and set imageAsset, e.g. 'assets/fish/bangus.png'.
/// Without it the screen shows a fish icon.
class FishSpecies {
  final String name; // must match the labels / recipe species names
  final String? englishName;
  final String descEn;
  final String descTl;
  final String? imageAsset;

  const FishSpecies({
    required this.name,
    required this.descEn,
    required this.descTl,
    this.englishName,
    this.imageAsset,
  });
}

const List<FishSpecies> supportedSpecies = [
  FishSpecies(
    name: 'Bangus',
    englishName: 'Milkfish',
    descEn:
        'The national fish of the Philippines. Silvery body, widely farmed in ponds and pens and sold fresh in markets. Often fried, grilled, or cooked as sinigang.',
    descTl:
        'Ang pambansang isda ng Pilipinas. Pilak ang katawan, karaniwang inaalagaan sa palaisdaan at ibinebenta sa palengke. Madalas iprito, iihaw, o gawing sinigang.',
  ),
  FishSpecies(
    name: 'Tilapia',
    descEn:
        'A freshwater fish widely farmed in ponds and cages. Mild-tasting and common in local markets. Often fried, grilled, or cooked in sweet and sour sauce.',
    descTl:
        'Isdang tabang na karaniwang inaalagaan sa palaisdaan at kulungan. Banayad ang lasa at karaniwan sa palengke. Madalas iprito, iihaw, o lutuin sa agridulce.',
  ),
  FishSpecies(
    name: 'Andohaw',
    englishName: 'Mackerel',
    descEn:
        'A mackerel-type fish with a slim, streamlined body. Often cooked fried, in coconut milk, or as fish steak.',
    descTl:
        'Isdang katulad ng mackerel na may balingkinitan at makinis na katawan. Madalas iprito, iluto sa gata, o gawing fish steak.',
  ),
  FishSpecies(
    name: 'Timbungan',
    descEn:
        'A fish commonly sold in the markets of Trinidad, Bohol. Often cooked as paksiw, fried, or in coconut milk.',
    descTl:
        'Isdang karaniwang ibinebenta sa mga palengke ng Trinidad, Bohol. Madalas gawing paksiw, iprito, o iluto sa gata.',
  ),
  FishSpecies(
    name: 'Silay',
    englishName: 'Bisugo',
    descEn:
        'Also called bisugo. Often fried, stewed in vinegar (paksiw), or dried as daing for breakfast.',
    descTl:
        'Tinatawag ding bisugo. Madalas iprito, gawing paksiw, o patuyuin bilang daing na pang-almusal.',
  ),
  FishSpecies(
    name: 'Carabalyas',
    descEn:
        'A fish commonly sold in the markets of Trinidad, Bohol. Often cooked as paksiw, fried, or in coconut milk.',
    descTl:
        'Isdang karaniwang ibinebenta sa mga palengke ng Trinidad, Bohol. Madalas gawing paksiw, iprito, o iluto sa gata.',
  ),
];

/// Just the names, in display order.
final List<String> kSpeciesNames = [for (final s in supportedSpecies) s.name];

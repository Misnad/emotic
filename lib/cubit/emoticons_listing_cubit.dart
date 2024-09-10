import 'package:emotic/core/emoticon.dart';
import 'package:emotic/cubit/emoticons_listing_state.dart';
import 'package:emotic/data/emoticons_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fuzzy/fuzzy.dart';

class EmoticonsListingCubit extends Cubit<EmoticonsListingState> {
  final EmoticonsRepository emoticonsRepository;
  EmoticonsListingCubit({
    required this.emoticonsRepository,
    required bool shouldLoadFromAsset,
  }) : super(EmoticonsListingInitial()) {
    loadEmoticons(shouldLoadFromAsset: shouldLoadFromAsset);
  }

  List<String> _getAllTags(List<Emoticon> emoticons) {
    Set<String> tags = {};
    for (var emoticon in emoticons) {
      tags.addAll(emoticon.emoticonTags);
    }
    return tags.toList();
  }

  void loadEmoticons({required bool shouldLoadFromAsset}) async {
    emit(EmoticonsListingLoading());
    final allEmoticons = await emoticonsRepository.getEmoticons(
        shouldLoadFromAsset: shouldLoadFromAsset);
    emit(
      EmoticonsListingLoaded(
        allEmoticons: allEmoticons,
        allTags: _getAllTags(allEmoticons),
        emoticonsToShow: allEmoticons,
      ),
    );
  }

  void updateEmoticon({required Emoticon emoticon}) async {
    await emoticonsRepository.saveEmoticon(emoticon: emoticon);
    loadEmoticons(shouldLoadFromAsset: false);
  }

  void searchEmoticons({required String searchTerm}) async {
    final localState = state;
    final searchTermTrimmed = searchTerm.trim();
    if (localState
        case EmoticonsListingLoaded(
          :final allEmoticons,
          :final allTags,
        )) {
      if (searchTermTrimmed.isEmpty) {
        emit(
          EmoticonsListingLoaded(
            allEmoticons: allEmoticons,
            allTags: allTags,
            emoticonsToShow: allEmoticons,
          ),
        );
        return;
      }

      final fuzzy = Fuzzy(allTags);
      final searchResult = fuzzy
          .search(searchTermTrimmed, 3)
          .map(
            (e) => e.item,
          )
          .toSet();
      final result = allEmoticons.where(
        (element) {
          return element.emoticonTags
              .toSet()
              .intersection(searchResult)
              .isNotEmpty;
        },
      ).toList();
      emit(
        EmoticonsListingLoaded(
          allEmoticons: allEmoticons,
          allTags: allTags,
          emoticonsToShow: result,
        ),
      );
    }
  }
}
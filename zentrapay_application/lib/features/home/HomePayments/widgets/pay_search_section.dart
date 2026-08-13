import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/models/search_result.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';

import 'search_result_tile.dart';

class PaySearchSection extends StatelessWidget {
  final TextEditingController controller;
  final bool isSearching;
  final ContactSearchResult searchResult;
  final ValueChanged<String> onChanged;
  final ValueChanged<SearchAppUser> onSelectUser;
  final ValueChanged<SearchBillProvider> onSelectBillProvider;
  final ValueChanged<SearchFundingSource> onSelectFundingSource;

  const PaySearchSection({
    super.key,
    required this.controller,
    required this.isSearching,
    required this.searchResult,
    required this.onChanged,
    required this.onSelectUser,
    required this.onSelectBillProvider,
    required this.onSelectFundingSource,
  });

  bool get _hasSearchResults =>
      searchResult.appUsers.isNotEmpty ||
      searchResult.billProviders.isNotEmpty ||
      searchResult.fundingSources.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SearchBar(
          controller: controller,
          hintText: "Search @zentag, phone, bank ac. no. etc",
          hintStyle: WidgetStateProperty.all(
            TextStyle(color: AppTheme.gray500, fontSize: 14),
          ),
          leading: const Icon(Icons.search, color: AppTheme.gray500),
          trailing: [
            if (isSearching)
              const Padding(
                padding: EdgeInsets.only(right: 8.0),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.primaryPink,
                  ),
                ),
              ),
          ],
          elevation: WidgetStateProperty.all(0),
          backgroundColor: WidgetStateProperty.all(AppTheme.gray100),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 15.0),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            ),
          ),
          onChanged: onChanged,
        ),
        if (controller.text.isNotEmpty)
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 250),
            child: _hasSearchResults
                ? SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...searchResult.appUsers.map(
                          (u) => SearchResultTile(
                            title: u.zentag,
                            subtitle: u.fullName,
                            dimmed: false,
                            onTap: () => onSelectUser(u),
                          ),
                        ),
                        ...searchResult.billProviders.map(
                          (b) => SearchResultTile(
                            title: b.billerName,
                            subtitle: "${b.categoryCode} · Coming soon",
                            dimmed: true,
                            onTap: () => onSelectBillProvider(b),
                          ),
                        ),
                        ...searchResult.fundingSources.map(
                          (f) => SearchResultTile(
                            title: f.sourceName,
                            subtitle: "${f.accountIdentifier} · Coming soon",
                            dimmed: true,
                            onTap: () => onSelectFundingSource(f),
                          ),
                        ),
                      ],
                    ),
                  )
                : Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: Text(
                        isSearching
                            ? "Searching system records..."
                            : "No matches found",
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.gray500,
                        ),
                      ),
                    ),
                  ),
          ),
      ],
    );
  }
}

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
  final ValueChanged<Banks> onSelectBank;

  const PaySearchSection({
    super.key,
    required this.controller,
    required this.isSearching,
    required this.searchResult,
    required this.onChanged,
    required this.onSelectUser,
    required this.onSelectBillProvider,
    required this.onSelectBank,
  });

  bool get _hasSearchResults =>
      searchResult.appUsers.isNotEmpty ||
      searchResult.billProviders.isNotEmpty ||
      searchResult.banks.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SearchBar(
          controller: controller,
          hintText: "Search...",
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
        const SizedBox(height: AppTheme.spacingMd),
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
                            // Search-contacts now returns a flat profile
                            // (no per-account zentag), so only show the
                            // zentag when present; otherwise lean on the
                            // contact's full name + phone.
                            title: u.fullName,
                            subtitle: u.fullName.isNotEmpty
                                ? u.fullName
                                : u.phoneNumber,
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
                        ...searchResult.banks.map(
                          (b) => SearchResultTile(
                            title: b.bankName,
                            subtitle: "${b.bankCode} · Coming soon",
                            dimmed: false,
                            onTap: () => onSelectBank(b),
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

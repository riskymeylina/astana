import 'package:flutter/material.dart';

import '../../models/property_model.dart';
import '../../services/property_service.dart';
import 'home_models.dart';

class HomeOfficeBranchCard extends StatelessWidget {
  final HomeOfficeBranch branch;
  final VoidCallback onOpenMap;
  final bool expanded;

  const HomeOfficeBranchCard({
    super.key,
    required this.branch,
    required this.onOpenMap,
    this.expanded = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: expanded ? double.infinity : 250,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8CFB0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE8C9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.apartment_rounded,
                  color: Color(0xFF8C4D14),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  branch.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF3A2B1F),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.place_rounded,
                size: 16,
                color: Color(0xFF8C4D14),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  branch.address,
                  style: const TextStyle(
                    fontSize: 12.8,
                    color: Color(0xFF6D5540),
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              const Icon(
                Icons.phone_rounded,
                size: 16,
                color: Color(0xFF8C4D14),
              ),
              const SizedBox(width: 6),
              Text(
                branch.phone,
                style: const TextStyle(
                  fontSize: 12.8,
                  color: Color(0xFF6D5540),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onOpenMap,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF2A642),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.map_rounded, size: 18),
              label: const Text(
                'Buka di Maps',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HomePromoCard extends StatelessWidget {
  final PropertyModel property;
  final String priceLabel;
  final VoidCallback onTap;

  const HomePromoCard({
    super.key,
    required this.property,
    required this.priceLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = property.gallery.isNotEmpty ? property.gallery.first.imageUrl : '';
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Color(0x26000000),
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) =>
                      Container(color: const Color(0xFFF0DCC0)),
                ),
                Container(color: Colors.black.withValues(alpha: 0.28)),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        property.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 19,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        property.category.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFF7E6CF),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Row(
                        children: [
                          const Icon(
                            Icons.place_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              property.location,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            priceLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HomePropertyGrid extends StatelessWidget {
  final List<PropertyModel> properties;
  final PropertyService propertyService;
  final ValueChanged<PropertyModel> onTap;

  const HomePropertyGrid({
    super.key,
    required this.properties,
    required this.propertyService,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: properties.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.82,
      ),
      itemBuilder: (context, index) {
        final property = properties[index];
        final imageUrl = property.gallery.isNotEmpty ? property.gallery.first.imageUrl : '';
        return InkWell(
          onTap: () => onTap(property),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFFF6E8),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFD8B88A)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(13),
                    ),
                    child: Image.network(
                      imageUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        color: const Color(0xFFFFE8C5),
                        child: const Center(
                          child: Icon(
                            Icons.image_not_supported_rounded,
                            color: Color(0xFF8E4E16),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        property.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF3A2B1F),
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        property.location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF6D5540),
                          fontWeight: FontWeight.w600,
                          fontSize: 12.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        propertyService.formatPrice(property.price),
                        style: const TextStyle(
                          color: Color(0xFF8E4E16),
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class HomeSectionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color backgroundColor;
  final BorderRadiusGeometry borderRadius;
  final BorderSide? borderSide;
  final List<BoxShadow>? boxShadow;

  const HomeSectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.backgroundColor = Colors.white,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.borderSide,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius,
        border: borderSide == null ? null : Border.fromBorderSide(borderSide!),
        boxShadow: boxShadow,
      ),
      child: child,
    );
  }
}

class HomeSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;

  const HomeSectionHeader({super.key, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: Color(0xFF3A2B1F),
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            style: const TextStyle(fontSize: 13.5, color: Color(0xFF6D5540)),
          ),
        ],
      ],
    );
  }
}

class HomePropertyStateCard extends StatelessWidget {
  final String message;
  final String buttonLabel;
  final VoidCallback onPressed;

  const HomePropertyStateCard({
    super.key,
    required this.message,
    required this.buttonLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return HomeSectionCard(
      padding: const EdgeInsets.all(18),
      borderSide: const BorderSide(color: Color(0xFFE8CFB0)),
      child: Column(
        children: [
          const Icon(
            Icons.home_work_rounded,
            size: 40,
            color: Color(0xFF8E4E16),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF574332),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E2B5B),
              foregroundColor: Colors.white,
            ),
            child: Text(buttonLabel),
          ),
        ],
      ),
    );
  }
}

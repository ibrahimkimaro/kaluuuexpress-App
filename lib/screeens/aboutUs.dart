import 'package:flutter/material.dart';

class AboutUsPage extends StatefulWidget {
  const AboutUsPage({super.key});

  @override
  State<AboutUsPage> createState() => _AboutUsPageState();
}

class _AboutUsPageState extends State<AboutUsPage> {
  // Blue sky color scheme
  static const Color skyBlue = Color(0xFF4A90E2);
  static const Color lightSkyBlue = Color(0xFF87CEEB);
  static const Color deepSkyBlue = Color(0xFF2E73B8);

  final List<Map<String, dynamic>> _values = [
    {
      'icon': Icons.speed_rounded,
      'title': 'Speed & Reliability',
      'description':
          'Fast delivery times with guaranteed safe arrival of your cargo.',
    },
    {
      'icon': Icons.security_rounded,
      'title': 'Security',
      'description': 'Advanced tracking and secure handling of all shipments.',
    },
    {
      'icon': Icons.support_agent_rounded,
      'title': '24/7 Support',
      'description':
          'Round-the-clock customer support for all your shipping needs.',
    },
    {
      'icon': Icons.eco_rounded,
      'title': 'Sustainability',
      'description':
          'Committed to eco-friendly practices in air cargo logistics.',
    },
  ];

  final List<Map<String, String>> _services = [
    {
      'title': 'Air Freight',
      'description':
          'Express air cargo services across East Africa and beyond.',
    },
    {
      'title': 'Door-to-Door Delivery',
      'description':
          'Complete logistics solutions from pickup to final destination.',
    },
    {
      'title': 'Customs Clearance',
      'description': 'Seamless customs handling for international shipments.',
    },
    {
      'title': 'Real-Time Tracking',
      'description':
          'Track your shipments anytime, anywhere with our mobile app.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: skyBlue),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'About Us',
          style: TextStyle(color: skyBlue, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // Hero Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [lightSkyBlue, skyBlue, deepSkyBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: skyBlue.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.local_shipping_rounded,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'KALUU EXPRESS CARGO',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Your Trusted Air Cargo Partner',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Our Story Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Our Story', Icons.auto_stories_rounded),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: skyBlue.withOpacity(0.08),
                          blurRadius: 15,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      'Kaluu Express Cargo was founded with a vision to revolutionize air freight services in East Africa. Starting from Tanzania, we have grown to become a leading air cargo provider, connecting businesses and individuals across the region.\n\n'
                      'Our journey began with a simple mission: to make international shipping accessible, reliable, and affordable for everyone. Today, we serve thousands of customers, handling everything from small parcels to large commercial shipments with the same dedication and care.\n\n'
                      'With our state-of-the-art tracking technology and commitment to customer satisfaction, we continue to set new standards in the air cargo industry.',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[700],
                        height: 1.6,
                      ),
                      textAlign: TextAlign.justify,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Our Values Section
                  _buildSectionTitle('Our Values', Icons.favorite_rounded),
                  const SizedBox(height: 16),

                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.85,
                        ),
                    itemCount: _values.length,
                    itemBuilder: (context, index) {
                      return _buildValueCard(
                        _values[index]['icon'],
                        _values[index]['title'],
                        _values[index]['description'],
                      );
                    },
                  ),

                  const SizedBox(height: 32),

                  // Our Services Section
                  _buildSectionTitle('Our Services', Icons.build_rounded),
                  const SizedBox(height: 16),

                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _services.length,
                    itemBuilder: (context, index) {
                      return _buildServiceCard(
                        _services[index]['title']!,
                        _services[index]['description']!,
                        index,
                      );
                    },
                  ),

                  const SizedBox(height: 32),

                  // Coverage Section
                  _buildSectionTitle('Our Coverage', Icons.map_rounded),
                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: skyBlue.withOpacity(0.08),
                          blurRadius: 15,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildCountryItem(
                          'Tanzania',
                          Icons.location_on_rounded,
                        ),
                        const Divider(height: 24),
                        _buildCountryItem('Kenya', Icons.location_on_rounded),
                        const Divider(height: 24),
                        _buildCountryItem('Rwanda', Icons.location_on_rounded),
                        const Divider(height: 24),
                        _buildCountryItem('Burundi', Icons.location_on_rounded),
                        const Divider(height: 24),
                        _buildCountryItem(
                          'Congo (DRC)',
                          Icons.location_on_rounded,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Contact Section
                  _buildSectionTitle(
                    'Get in Touch',
                    Icons.contact_mail_rounded,
                  ),
                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          lightSkyBlue.withOpacity(0.1),
                          skyBlue.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: skyBlue.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildContactItem(
                          Icons.email_rounded,
                          'Email',
                          'Kaluuexpressaircargo@gmail.com',
                        ),
                        const SizedBox(height: 16),
                        _buildContactItem(
                          Icons.phone_rounded,
                          'Phone',
                          '+255 759 420 034',
                        ),
                        const SizedBox(height: 16),
                        _buildContactItem(
                          Icons.language_rounded,
                          'Coverage',
                          'East Africa Region',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Mission Statement
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [lightSkyBlue, skyBlue],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: skyBlue.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.rocket_launch_rounded,
                          color: Colors.white,
                          size: 40,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Our Mission',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'To provide exceptional air cargo services that connect East Africa to the world, ensuring every shipment reaches its destination safely, swiftly, and affordably.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.95),
                            height: 1.6,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [lightSkyBlue, skyBlue]),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: skyBlue,
          ),
        ),
      ],
    );
  }

  Widget _buildValueCard(IconData icon, String title, String description) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: skyBlue.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [lightSkyBlue, skyBlue]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: skyBlue,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(String title, String description, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: skyBlue.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [lightSkyBlue, skyBlue]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: skyBlue,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountryItem(String country, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: skyBlue, size: 20),
        const SizedBox(width: 12),
        Text(
          country,
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey[800],
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildContactItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [lightSkyBlue, skyBlue]),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: skyBlue,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

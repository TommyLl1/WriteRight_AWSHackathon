import 'package:flutter/material.dart';
import 'package:writeright/new/utils/constants.dart';

class BuildInfoWidget extends StatelessWidget {
  final bool showDetailed;

  const BuildInfoWidget({Key? key, this.showDetailed = false})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (showDetailed) {
      return Card(
        margin: const EdgeInsets.all(8.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Build Information',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              _buildInfoRow('Commit Hash', AppConstants.shortCommitHash),
              _buildInfoRow('Branch', AppConstants.buildBranch),
              _buildInfoRow('Build Number', AppConstants.buildNumber),
              _buildInfoRow('Build Time', AppConstants.buildTimestamp),
            ],
          ),
        ),
      );
    } else {
      return Text(
        'v${AppConstants.buildNumber} (${AppConstants.shortCommitHash})',
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: Colors.grey),
      );
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: SelectableText(value)),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

class FilterBar extends StatelessWidget {
  final List<Map> dateRangeOptions = [
    {'name': 'Past week', 'value': '1_week'},
    {'name': 'Past month', 'value': '1_month'},
    {'name': 'Past year', 'value': '1_year'},
    {'name': 'All time', 'value': 'all'}
  ];
  final int recordingsLength;
  final bool filterOpen;
  final String selectedOption;
  final Function filterOpenToggle;
  final Function selectFilterOption;

  FilterBar({
    this.recordingsLength,
    this.filterOpen,
    this.selectedOption,
    this.filterOpenToggle,
    this.selectFilterOption,
  });

  @override
  Widget build(BuildContext context) {
    Map option = dateRangeOptions
        .firstWhere((option) => option['value'] == selectedOption);
    String filterText = 'Display: ${option['name']}';

    List<Widget> filterBarContents = [
      Container(
          padding: EdgeInsets.only(left: 10.0, right: 5.0),
          child: Row(children: [
            Expanded(child: Text(filterText)),
            Text('$recordingsLength recordings'),
            IconButton(
              icon: Icon(Icons.filter_list),
              onPressed: filterOpenToggle,
            ),
          ]))
    ];

    if (filterOpen) {
      filterBarContents += dateRangeOptions.map((element) {
        return RadioListTile(
          title: Text(element['name']),
          value: element['value'],
          groupValue: selectedOption,
          onChanged: selectFilterOption,
        );
      }).toList();
    }

    return Column(children: filterBarContents);
  }
}

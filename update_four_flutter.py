from pathlib import Path
import re

files = {
    Path(r"c:\Users\User\Desktop\YouWell\youwell\lib\Administrador\ruido.dart"): ("Ruído", "ruido", "Colors.blue"),
    Path(r"c:\Users\User\Desktop\YouWell\youwell\lib\Administrador\qualidade_ar.dart"): ("Qualidade do Ar", "ar", "Colors.teal"),
    Path(r"c:\Users\User\Desktop\YouWell\youwell\lib\Gerente\ruido.dart"): ("Ruído", "ruido", "Colors.blue"),
    Path(r"c:\Users\User\Desktop\YouWell\youwell\lib\Gerente\qualidade_ar.dart"): ("Qualidade do Ar", "ar", "Colors.teal"),
}

for path, (title, field, color) in files.items():
    text = path.read_text(encoding="utf-8")

    text = text.replace("backgroundColor: const Color.fromARGB(255, 230, 230, 230),", "backgroundColor: const Color(0xFFF4F7F5),")
    text = text.replace("backgroundColor: const Color.fromARGB(255, 161, 161, 161),", "backgroundColor: const Color.fromARGB(255, 10, 85, 64),")

    marker = "  @override\n  Widget build(BuildContext context) {"
    method = f'''  String _formatarData(String data) {{
    final partes = data.split('-');
    if (partes.length != 3) return data;

    return '${{partes[2].padLeft(2, '0')}}/${{partes[1].padLeft(2, '0')}}/${{partes[0]}}';
  }}

'''
    if "String _formatarData(String data)" not in text:
        text = text.replace(marker, method + marker, 1)

    body = f'''      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Card(
                elevation: 2,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Text(
                          '{title}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 10, 85, 64),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Center(
                        child: Text(
                          'Variação ao longo do dia',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 230,
                        child: LineChart(
                          LineChartData(
                            minY: 40,
                            maxY: 80,
                            gridData: FlGridData(
                              show: true,
                              horizontalInterval: 5,
                              verticalInterval: 2,
                              getDrawingHorizontalLine: (value) => FlLine(
                                color: Colors.grey.withValues(alpha: 0.18),
                                strokeWidth: 1,
                              ),
                              getDrawingVerticalLine: (value) => FlLine(
                                color: Colors.grey.withValues(alpha: 0.12),
                                strokeWidth: 1,
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            titlesData: FlTitlesData(
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  interval: 1,
                                  reservedSize: 30,
                                  getTitlesWidget: (value, meta) {{
                                    final indice = value.toInt();
                                    if (indice >= 0 && indice < sensores.length) {{
                                      return Text(
                                        sensores[indice]["hora"],
                                        style: TextStyle(color: Colors.grey[600], fontSize: 10),
                                      );
                                    }}
                                    return const Text('');
                                  }},
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 45,
                                  interval: 10,
                                  getTitlesWidget: (value, meta) => Text(
                                    value.toInt().toString(),
                                    style: TextStyle(color: Colors.grey[600], fontSize: 11),
                                  ),
                                ),
                              ),
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                            lineBarsData: [
                              LineChartBarData(
                                spots: sensores.asMap().entries.map((item) {{
                                  final indice = item.key;
                                  final valor = item.value["{field}"].toDouble();
                                  return FlSpot(indice.toDouble(), valor);
                                }}).toList(),
                                isCurved: true,
                                color: {color},
                                barWidth: 3,
                                dotData: const FlDotData(show: true),
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: {color}.withValues(alpha: 0.12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Card(
                elevation: 2,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(
                        child: Text(
                          'Histórico detalhado',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 10, 85, 64),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Table(
                        columnWidths: const {{
                          0: FlexColumnWidth(1.5),
                          1: FlexColumnWidth(1),
                          2: FlexColumnWidth(1),
                        }},
                        children: [
                          const TableRow(
                            children: [
                              Padding(
                                padding: EdgeInsets.all(5),
                                child: Text('Data', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                              Padding(
                                padding: EdgeInsets.all(5),
                                child: Text('Hora', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                              Padding(
                                padding: EdgeInsets.all(5),
                                child: Text('Valor', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          ...sensores.map((dado) {{
                            return TableRow(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(5),
                                  child: Text(_formatarData(dado["data"])),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(5),
                                  child: Text(dado["hora"]),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(5),
                                  child: Text('${{dado["{field}"]}}'),
                                ),
                              ],
                            );
                          }}),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),'''

    start = text.find("      body:")
    if start == -1:
        raise RuntimeError(f"body not found in {path}")
    end_marker = "\n    );\n  }\n}"
    end = text.find(end_marker, start)
    if end == -1:
        raise RuntimeError(f"end not found in {path}")
    text = text[:start] + body + text[end:end+len(end_marker)].replace("\n    );", "\n    );", 1)

    path.write_text(text, encoding="utf-8")
    print(path)

import CreateML
import Foundation

public final class CICBinaryConfusionMatrix {
    private let dataTable: MLDataTable
    private let predictedColumn: String
    private let actualColumn: String
    private let positiveClass: String

    public private(set) var matrix: [[Int]]

    public static func validateDataTable(
        _ dataTable: MLDataTable,
        predictedColumn: String,
        actualColumn: String
    ) -> Bool {
        // データの有効性チェック
        guard !dataTable.rows.isEmpty else {
            print("⚠️ データテーブルが空です")
            return false
        }

        guard dataTable.columnNames.contains(predictedColumn) else {
            print("❌ エラー: 予測列 '\(predictedColumn)' が存在しません")
            print("   利用可能な列: \(dataTable.columnNames.joined(separator: ", "))")
            return false
        }

        guard dataTable.columnNames.contains(actualColumn) else {
            print("❌ エラー: 実際の値の列 '\(actualColumn)' が存在しません")
            print("   利用可能な列: \(dataTable.columnNames.joined(separator: ", "))")
            return false
        }

        // ラベルの取得とソート
        let labelSet = Set(dataTable.rows.compactMap { $0[actualColumn]?.stringValue })
        let sortedLabels = Array(labelSet).sorted()

        // ラベルが存在することを確認
        guard !sortedLabels.isEmpty, sortedLabels.count == 2 else {
            print("❌ エラー: 2クラス分類ではありません。検出されたクラス数: \(sortedLabels.count)")
            return false
        }

        return true
    }

    public init?(dataTable: MLDataTable, predictedColumn: String, actualColumn: String, positiveClass: String) {
        self.dataTable = dataTable
        self.predictedColumn = predictedColumn
        self.actualColumn = actualColumn
        self.positiveClass = positiveClass

        // データの有効性チェック
        guard Self.validateDataTable(dataTable, predictedColumn: predictedColumn, actualColumn: actualColumn) else {
            return nil
        }

        // 混同行列の初期化
        matrix = Array(repeating: Array(repeating: 0, count: 2), count: 2)

        // 混同行列の計算
        for row in dataTable.rows {
            guard let actualLabel = row[actualColumn]?.stringValue,
                  let predictedLabel = row[predictedColumn]?.stringValue,
                  let count = row["Count"]?.intValue
            else {
                continue
            }

            // positiveClassに基づいてインデックスを決定
            let actualIndex = actualLabel == positiveClass ? 1 : 0
            let predictedIndex = predictedLabel == positiveClass ? 1 : 0

            matrix[actualIndex][predictedIndex] += count
        }
    }

    public var truePositive: Int { matrix[1][1] }
    public var falsePositive: Int { matrix[0][1] }
    public var falseNegative: Int { matrix[1][0] }
    public var trueNegative: Int { matrix[0][0] }

    public var recall: Double {
        calculateRecall(truePositives: truePositive, falseNegatives: falseNegative)
    }

    public var precision: Double {
        calculatePrecision(truePositives: truePositive, falsePositives: falsePositive)
    }

    public var accuracy: Double {
        let total = truePositive + falsePositive + falseNegative + trueNegative
        return total == 0 ? 0.0 : Double(truePositive + trueNegative) / Double(total)
    }

    public var f1Score: Double {
        calculateF1Score(recall: recall, precision: precision)
    }

    private func calculateRecall(truePositives: Int, falseNegatives: Int) -> Double {
        let denominator = truePositives + falseNegatives
        return denominator == 0 ? 0.0 : Double(truePositives) / Double(denominator)
    }

    private func calculatePrecision(truePositives: Int, falsePositives: Int) -> Double {
        let denominator = truePositives + falsePositives
        return denominator == 0 ? 0.0 : Double(truePositives) / Double(denominator)
    }

    private func calculateF1Score(recall: Double, precision: Double) -> Double {
        let denominator = recall + precision
        return denominator == 0 ? 0.0 : 2 * (recall * precision) / denominator
    }

    public func getMatrixGraph() -> String {
        var result = ""

        // ヘッダー行
        result += "Actual\\Predicted | Positive | Negative\n"

        // 各行（Positive->Negativeの順）
        result += "Positive | \(matrix[1][1]) | \(matrix[1][0])\n"
        result += "Negative | \(matrix[0][1]) | \(matrix[0][0])\n"

        return result
    }
}

//
//  ContentView.swift
//  NLPApp
//
//  Created by Raymond Lei on 5/12/25.
//

import SwiftUI
import NaturalLanguage

struct ContentView: View {
    @State private var inputText: String = ""
    @State private var sentiment: String = "等待输入..."
    @State private var language: String = "等待输入..."
    @State private var tokens: [String] = []
    @State private var entities: [(String, String)] = []
    @State private var posTags: [(String, String)] = []
    @State private var textCategory: String = "等待输入..."
    
    private let sampleTexts = [
        "今天天气真好，阳光明媚，让人心情愉悦！",
        "这部电影太糟糕了，浪费了我两个小时的时间。",
        "The weather is beautiful today, and I'm feeling great!",
        "This product exceeded my expectations. I'm very satisfied with the quality.",
        "苹果公司CEO蒂姆·库克今天在北京访问了小米公司。",
        "The quick brown fox jumps over the lazy dog in New York City."
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    TextEditor(text: $inputText)
                        .frame(height: 150)
                        .padding(4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray, lineWidth: 1)
                        )
                        .padding(.horizontal)
                    
                    HStack(spacing: 15) {
                        Button(action: analyzeText) {
                            Text("分析文本")
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(8)
                        }
                        
                        Button(action: useSampleText) {
                            Text("使用示例")
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.green)
                                .cornerRadius(8)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 10) {
                        ResultRow(title: "情感分析", value: sentiment)
                        ResultRow(title: "语言检测", value: language)
                        ResultRow(title: "文本分类", value: textCategory)
                        
                        if !tokens.isEmpty {
                            Text("分词结果：")
                                .font(.headline)
                            ScrollView {
                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 8) {
                                    ForEach(tokens, id: \.self) { token in
                                        Text(token)
                                            .padding(8)
                                            .background(Color.gray.opacity(0.2))
                                            .cornerRadius(4)
                                    }
                                }
                            }
                            .frame(height: 100)
                        }
                        
                        if !entities.isEmpty {
                            Text("命名实体：")
                                .font(.headline)
                            ForEach(entities, id: \.0) { entity in
                                HStack {
                                    Text(entity.0)
                                        .padding(8)
                                        .background(Color.blue.opacity(0.2))
                                        .cornerRadius(4)
                                    Text("(\(entity.1))")
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        
                        if !posTags.isEmpty {
                            Text("词性标注：")
                                .font(.headline)
                            ForEach(posTags, id: \.0) { tag in
                                HStack {
                                    Text(tag.0)
                                        .padding(8)
                                        .background(Color.purple.opacity(0.2))
                                        .cornerRadius(4)
                                    Text("(\(tag.1))")
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("NLP 分析器")
        }
    }
    
    private func analyzeText() {
        // 情感分析
        let tagger = NLTagger(tagSchemes: [.sentimentScore])
        tagger.string = inputText
        if let sentimentScore = tagger.tag(at: inputText.startIndex, unit: .paragraph, scheme: .sentimentScore).0?.rawValue {
            let score = Double(sentimentScore) ?? 0
            sentiment = score > 0 ? "积极" : score < 0 ? "消极" : "中性"
        }
        
        // 语言检测
        let languageTagger = NLTagger(tagSchemes: [.language])
        languageTagger.string = inputText
        if let detectedLanguage = languageTagger.dominantLanguage {
            language = detectedLanguage.rawValue
        }
        
        // 分词
        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = inputText
        tokens = tokenizer.tokens(for: inputText.startIndex..<inputText.endIndex).map { String(inputText[$0]) }
        
        // 命名实体识别
        let entityTagger = NLTagger(tagSchemes: [.nameType])
        entityTagger.string = inputText
        entities = []
        entityTagger.enumerateTags(in: inputText.startIndex..<inputText.endIndex, unit: .word, scheme: .nameType) { tag, range in
            if let tag = tag {
                let entity = String(inputText[range])
                let type = getEntityType(tag)
                entities.append((entity, type))
            }
            return true
        }
        
        // 词性标注
        let posTagger = NLTagger(tagSchemes: [.lexicalClass])
        posTagger.string = inputText
        posTags = []
        posTagger.enumerateTags(in: inputText.startIndex..<inputText.endIndex, unit: .word, scheme: .lexicalClass) { tag, range in
            if let tag = tag {
                let word = String(inputText[range])
                let pos = getPOSType(tag)
                posTags.append((word, pos))
            }
            return true
        }
        
        // 文本分类
        textCategory = classifyText(inputText)
    }
    
    private func getEntityType(_ tag: NLTag) -> String {
        switch tag {
        case .personalName: return "人名"
        case .placeName: return "地名"
        case .organizationName: return "组织"
        default: return "其他"
        }
    }
    
    private func getPOSType(_ tag: NLTag) -> String {
        switch tag {
        case .noun: return "名词"
        case .verb: return "动词"
        case .adjective: return "形容词"
        case .adverb: return "副词"
        case .pronoun: return "代词"
        case .determiner: return "限定词"
        case .preposition: return "介词"
        case .conjunction: return "连词"
        case .number: return "数词"
        default: return "其他"
        }
    }
    
    private func classifyText(_ text: String) -> String {
        // 简单的文本分类逻辑
        let lowercased = text.lowercased()
        if lowercased.contains("天气") || lowercased.contains("weather") {
            return "天气相关"
        } else if lowercased.contains("电影") || lowercased.contains("movie") {
            return "电影相关"
        } else if lowercased.contains("产品") || lowercased.contains("product") {
            return "产品相关"
        } else if lowercased.contains("公司") || lowercased.contains("company") {
            return "商业相关"
        } else {
            return "其他"
        }
    }
    
    private func useSampleText() {
        inputText = sampleTexts.randomElement() ?? ""
        analyzeText()
    }
}

struct ResultRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    ContentView()
}

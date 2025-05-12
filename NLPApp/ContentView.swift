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
    
    private let sampleTexts = [
        "今天天气真好，阳光明媚，让人心情愉悦！",
        "这部电影太糟糕了，浪费了我两个小时的时间。",
        "The weather is beautiful today, and I'm feeling great!",
        "This product exceeded my expectations. I'm very satisfied with the quality."
    ]
    
    var body: some View {
        NavigationView {
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
                }
                .padding()
                
                Spacer()
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

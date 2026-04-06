// 关于页面 — 软件功能介绍、项目主页、作者信息、技术栈、开源许可

import { Colors, Typography, Spacing, Radius, ComponentSize } from '../constants/DesignTokens'

@Component
export struct AboutPageContent {
  @Consume('navPathStack') navPathStack: NavPathStack

  build() {
    NavDestination() {
      Column() {
        // 标题栏
        Row() {
          SymbolGlyph($r('sys.symbol.chevron_left'))
            .fontSize(ComponentSize.ICON_LG)
            .fontColor([Colors.TEXT_PRIMARY])
            .onClick(() => { this.navPathStack.pop() })

          Text('关于')
            .fontSize(Typography.TITLE)
            .fontWeight(FontWeight.Bold)
            .fontColor(Colors.TEXT_PRIMARY)
            .margin({ left: Spacing.SM })

          Blank()
        }
        .width('100%')
        .padding({ left: Spacing.BASE, right: Spacing.BASE, top: Spacing.SM, bottom: Spacing.SM })

        Scroll() {
          Column({ space: Spacing.BASE }) {
            // 应用图标 + 名称 + 版本
            this.AppHeader()

            // 功能介绍
            this.FeatureSection()

            // 项目信息
            this.ProjectSection()

            // 作者信息
            this.AuthorSection()

            // 技术栈
            this.TechStackSection()

            // 开源许可
            this.LicenseSection()

            // 底部留白
            Column()
              .height(Spacing.XL)
          }
          .width('100%')
          .padding({ left: Spacing.BASE, right: Spacing.BASE, bottom: Spacing.XL })
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      }
      .width('100%')
      .height('100%')
      .backgroundColor(Colors.BG_PRIMARY)
    }
    .hideTitleBar(true)
  }

  @Builder
  AppHeader() {
    Column({ space: Spacing.SM }) {
      // 应用图标
      Column() {
        Text('WP')
          .fontSize(32)
          .fontWeight(FontWeight.Bold)
          .fontColor(Colors.TEXT_ON_PRIMARY)
      }
      .width(80)
      .height(80)
      .borderRadius(Radius.XL)
      .backgroundColor(Colors.PRIMARY)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)

      Text('WordPress CMS')
        .fontSize(Typography.TITLE)
        .fontWeight(FontWeight.Bold)
        .fontColor(Colors.TEXT_PRIMARY)

      Text('AI \u9a71\u52a8\u7684 WordPress \u5185\u5bb9\u7ba1\u7406\u7cfb\u7edf')
        .fontSize(Typography.BODY)
        .fontColor(Colors.TEXT_SECONDARY)

      Text('v1.0.0')
        .fontSize(Typography.CAPTION)
        .fontColor(Colors.TEXT_HINT)
        .padding({ left: Spacing.MD, right: Spacing.MD, top: Spacing.XS, bottom: Spacing.XS })
        .backgroundColor(Colors.BG_SECONDARY)
      .borderRadius(Radius.FULL)
      .margin({ right: Spacing.SM, bottom: Spacing.SM })
    }
    .width('100%')
    .padding({ top: Spacing.LG, bottom: Spacing.LG })
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  FeatureSection() {
    Column({ space: Spacing.SM }) {
      this.SectionTitle('\u6838\u5fc3\u529f\u80fd')

      this.FeatureItem('square_and_pencil', 'AI \u667a\u80fd\u5199\u4f5c', '\u652f\u6301 OpenAI\u3001DeepSeek\u3001\u963f\u91cc\u4e91\u767e\u70bc\u7b49\u591a\u79cd AI \u670d\u52a1\uff0c\u6d41\u5f0f\u751f\u6210\u9ad8\u8d28\u91cf\u6587\u7ae0')
      this.FeatureItem('link', '\u591a\u7ad9\u70b9\u7ba1\u7406', '\u96c6\u4e2d\u7ba1\u7406\u591a\u4e2a WordPress \u7ad9\u70b9\uff0c\u4e00\u952e\u53d1\u5e03\u6587\u7ae0')
      this.FeatureItem('camera', 'AI \u914d\u56fe', '\u652f\u6301 DALL-E\u3001\u901a\u4e49\u4e07\u76f8\u3001Stable Diffusion \u7b49 8 \u79cd\u56fe\u7247\u751f\u6210\u670d\u52a1')
      this.FeatureItem('doc_text', 'Markdown \u7f16\u8f91\u5668', '\u5185\u7f6e\u683c\u5f0f\u5316\u5de5\u5177\u680f\uff0c\u652f\u6301\u5b9e\u65f6\u9884\u89c8')
      this.FeatureItem('folder', '\u6a21\u677f\u5e93', '\u9884\u7f6e\u591a\u79cd\u6587\u7ae0\u6a21\u677f\uff0c\u652f\u6301\u81ea\u5b9a\u4e49\u521b\u5efa')
      this.FeatureItem('magnifyingglass', '\u5173\u952e\u8bcd\u7ba1\u7406', '\u5206\u7ec4\u7ba1\u7406\u5173\u952e\u8bcd\uff0c\u652f\u6301\u6279\u91cf\u5bfc\u5165\u5bfc\u51fa')
      this.FeatureItem('highlighter_line', '\u4e3b\u9898\u7ba1\u7406', '\u7ec4\u7ec7\u7ba1\u7406\u5185\u5bb9\u4e3b\u9898\uff0c\u667a\u80fd\u5206\u914d')
      this.FeatureItem('square_and_arrow_down', '\u6570\u636e\u5907\u4efd', '\u52a0\u5bc6\u5bfc\u51fa/\u5bfc\u5165\uff0c\u5206\u7c7b\u5907\u4efd\uff0c\u6570\u636e\u5b89\u5168\u65e0\u5fe7')
      this.FeatureItem('lock_shield', '\u672c\u5730\u5b58\u50a8', '\u6240\u6709\u6570\u636e\u5b58\u50a8\u5728\u672c\u5730\uff0c\u5bc6\u7801\u52a0\u5bc6\u5b58\u50a8\uff0c\u4fdd\u62a4\u9690\u79c1\u5b89\u5168')
    }
    .width('100%')
    .padding(Spacing.BASE)
    .backgroundColor(Colors.BG_SECONDARY)
    .borderRadius(Radius.LG)
  }

  @Builder
  ProjectSection() {
    Column({ space: Spacing.SM }) {
      this.SectionTitle('\u9879\u76ee\u4fe1\u606f')

      this.InfoRow('\u9879\u76ee\u4e3b\u9875', 'github.com/encorexin/WordPressCMS')
      this.InfoRow('\u5f00\u6e90\u534f\u8bae', 'MIT License')
      this.InfoRow('\u5e73\u53f0\u652f\u6301', 'Web / HarmonyOS / Android')
    }
    .width('100%')
    .padding(Spacing.BASE)
    .backgroundColor(Colors.BG_SECONDARY)
    .borderRadius(Radius.LG)
  }

  @Builder
  AuthorSection() {
    Column({ space: Spacing.SM }) {
      this.SectionTitle('\u4f5c\u8005\u4fe1\u606f')

      Row({ space: Spacing.MD }) {
        Column() {
          SymbolGlyph($r('sys.symbol.person_2'))
            .fontSize(40)
            .fontColor([Colors.PRIMARY])
        }

        Column({ space: Spacing.XS }) {
          Text('encorexin')
            .fontSize(Typography.BODY_LARGE)
            .fontWeight(FontWeight.Medium)
            .fontColor(Colors.TEXT_PRIMARY)

          Text('github.com/encorexin')
            .fontSize(Typography.CAPTION)
            .fontColor(Colors.PRIMARY)
        }
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .padding({ top: Spacing.XS })
    }
    .width('100%')
    .padding(Spacing.BASE)
    .backgroundColor(Colors.BG_SECONDARY)
    .borderRadius(Radius.LG)
  }

  @Builder
  TechStackSection() {
    Column({ space: Spacing.SM }) {
      this.SectionTitle('\u6280\u672f\u6808')

      Flex({ wrap: FlexWrap.Wrap }) {
        this.TechBadge('ArkTS')
        this.TechBadge('ArkUI')
        this.TechBadge('HarmonyOS')
        this.TechBadge('React 18')
        this.TechBadge('TypeScript 5')
        this.TechBadge('Vite 5')
        this.TechBadge('Tailwind CSS')
        this.TechBadge('RDB \u5173\u7cfb\u6570\u636e\u5e93')
        this.TechBadge('IndexedDB')
      }
      .width('100%')
      .padding({ top: Spacing.XS })
    }
    .width('100%')
    .padding(Spacing.BASE)
    .backgroundColor(Colors.BG_SECONDARY)
    .borderRadius(Radius.LG)
  }

  @Builder
  LicenseSection() {
    Column({ space: Spacing.SM }) {
      this.SectionTitle('\u5f00\u6e90\u8bb8\u53ef')

      Text('MIT License')
        .fontSize(Typography.BODY_LARGE)
        .fontWeight(FontWeight.Medium)
        .fontColor(Colors.TEXT_PRIMARY)

      Text('Copyright (c) 2024-2025 encorexin\n\nPermission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:\n\nThe above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.')
        .fontSize(Typography.CAPTION)
        .fontColor(Colors.TEXT_SECONDARY)
        .lineHeight(18)
    }
    .width('100%')
    .padding(Spacing.BASE)
    .backgroundColor(Colors.BG_SECONDARY)
    .borderRadius(Radius.LG)
  }

  @Builder
  SectionTitle(title: string) {
    Text(title)
      .fontSize(Typography.SUBTITLE)
      .fontWeight(FontWeight.Bold)
      .fontColor(Colors.TEXT_PRIMARY)
      .width('100%')
  }

  @Builder
  FeatureItem(iconName: string, title: string, desc: string) {
    Row({ space: Spacing.MD }) {
      SymbolGlyph($r(`sys.symbol.${iconName}`))
        .fontSize(ComponentSize.ICON_MD)
        .fontColor([Colors.PRIMARY])
        .margin({ top: 2 })

      Column({ space: 2 }) {
        Text(title)
          .fontSize(Typography.BODY)
          .fontWeight(FontWeight.Medium)
          .fontColor(Colors.TEXT_PRIMARY)

        Text(desc)
          .fontSize(Typography.CAPTION)
          .fontColor(Colors.TEXT_SECONDARY)
          .lineHeight(16)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding({ top: Spacing.XS, bottom: Spacing.XS })
  }

  @Builder
  InfoRow(label: string, value: string) {
    Row() {
      Text(label)
        .fontSize(Typography.BODY)
        .fontColor(Colors.TEXT_SECONDARY)

      Blank()

      Text(value)
        .fontSize(Typography.BODY)
        .fontColor(Colors.TEXT_PRIMARY)
        .fontWeight(FontWeight.Medium)
    }
    .width('100%')
    .padding({ top: Spacing.XS, bottom: Spacing.XS })
  }

  @Builder
  TechBadge(name: string) {
    Text(name)
      .fontSize(Typography.CAPTION)
      .fontColor(Colors.PRIMARY)
      .padding({ left: Spacing.MD, right: Spacing.MD, top: Spacing.XS, bottom: Spacing.XS })
      .backgroundColor('#E6F0FF')
      .borderRadius(Radius.FULL)
      .margin({ right: Spacing.SM, bottom: Spacing.SM })
  }
}

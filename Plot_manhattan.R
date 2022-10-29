#!/usr/bin/Rscript
R语言|绘制曼哈顿图
曼哈顿图（manhattan Plot）是一种散点图，因形似曼哈顿摩天大楼而命名，常用于全基因组关联研究（GWAS）以显示重要的SNP。曼哈顿图作为经典的可视化方式，通常用于显示具有大量数据点，许多非零振幅和更高振幅值分布的数据，不仅可以展示数据全貌，又能快速找到目标基因或OTU，同时可知目标的具体位置和分类、显著程度等信息。

作者：维凡生物
链接：http://events.jianshu.io/p/00d7c8a70dc4
来源：简书
1.调用qqman 包 manhattan()命令绘制 GWAS 曼哈顿图；

library(qqman)

#使用自带的数据集 gwasResults 作示例
data(gwasResults)
head(gwasResults)

#默认作图函数，详情 ?manhattan
#定义 p < 1e-05 为临界显著性，p < 5e-08 为高可信显著性

manhattan(gwasResults, col = c("royalblue4", "darksalmon"), suggestiveline = -log10(1e-05), genomewideline = -log10(5e-08), annotatePval = 5e-08, annotateTop = FALSE)

2.ggplot2 绘制 GWAS 曼哈顿图;
##ggplot2 绘制 GWAS 曼哈顿图
library(ggplot2)

#计算染色体刻度坐标
gwasResults$SNP1 <- seq(1, nrow(gwasResults), 1)
gwasResults$CHR <- factor(gwasResults$CHR, levels = unique(gwasResults$CHR))
chr <- aggregate(gwasResults$SNP1, by = list(gwasResults$CHR), FUN = median)

#ggplot2 作图
#定义 p < 1e-05 为临界显著性，p < 5e-08 为高可信显著性
p <- ggplot(gwasResults, aes(SNP1, -log(P, 10))) +
  annotate('rect', xmin = 0, xmax = max(gwasResults$SNP1), ymin = -log10(1e-05), ymax = -log10(5e-08), fill = 'gray98') +
  geom_hline(yintercept = c(-log10(1e-05), -log10(5e-08)), color = c("#F39B7FB2","#91D1C2B2"), size = 0.35) +
  geom_point(aes(color = CHR), show.legend = FALSE) +
  scale_color_manual(values = rep(c("grey", "skyblue"), 11)) +
  scale_x_continuous(breaks = chr$x, labels = chr$Group.1, expand = c(0, 0)) +
  scale_y_continuous(breaks = seq(1, 9, 2), labels = as.character(seq(1, 9, 2)), expand = c(0, 0), limits = c(0, 9)) +
  theme(panel.grid = element_blank(), axis.line = element_line(colour = 'black'), panel.background = element_rect(fill = 'transparent')) +
  labs(x = 'Chromosome', y = expression(''~-log[10]~'(P)'))

p

3.借助 ggrepel 包，标记高可信水平的 SNP 名称；

library(ggrepel)

gwasResults1 <- subset(gwasResults, P < 5e-08)

p1 <- p + geom_text_repel(data = gwasResults1, aes(label = SNP), size = 3,box.padding = unit(0.5, 'lines'), segment.color = "royalblue4", show.legend = FALSE, color = "royalblue4")

p1

#ggsave('GWAS_gg.png', p1, width = 10, height = 4.5)

4.ggplot2 绘制 OTUs 差异富集曼哈顿图。

#读取数据
otu_stat <- read.delim('otu_sign.txt', sep = '\t')

#门水平排序，这里直接按首字母排序了
otu_stat <- otu_stat[order(otu_stat$phylum), ]
otu_stat$otu_sort <- 1:nrow(otu_stat)

#其它自定义排序，例如想根据 OTU 数量降序排序
#phylum_num <- phylum_num[order(phylum_num, decreasing = TRUE)]
#otu_stat$phylum <- factor(otu_stat$phylum, levels = names(phylum_num))
#otu_stat <- otu_stat[order(otu_stat$phylum), ]
#otu_stat$otu_sort <- 1:nrow(otu_stat)
#计算 x 轴标签、矩形区块对应的 x 轴位置
phylum_num <- summary(otu_stat$phylum)
phylum_num <-  as.numeric(as.factor(phylum_num))
phylum_range <- c(0, phylum_num[1])
phylum_name <- phylum_num[1] / 2
for (i in 2:length(phylum_num)) {
  phylum_range[i+1] <- phylum_range[i] + phylum_num[i]
  phylum_name[i] <- phylum_range[i] + phylum_num[i] / 2
}

#推荐先调整好背景（矩形区块），再绘制散点，这样散点位于矩形区块图层的上面，更清晰
#整体布局，坐标轴、背景线、标签等
p <- ggplot(otu_stat, aes(otu_sort, -log(p_value, 10))) +
  labs(x = NULL, y = expression(''~-log[10]~'(P)'), size = 'relative abundance (%)', shape = 'significantly enriched') +
  theme(panel.grid = element_blank(), axis.line = element_line(colour = 'black'), panel.background = element_rect(fill = 'transparent'), legend.key = element_rect(fill = 'transparent')) +
  scale_x_continuous(breaks = phylum_name, labels = names(phylum_num), expand = c(0, 0)) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1, vjust = 1))

#矩形背景
for (i in 1:(length(phylum_range) - 1)) p <- p + annotate('rect', xmin = phylum_range[i], xmax = phylum_range[i+1], ymin = -Inf, ymax = Inf, fill = ifelse(i %% 2 == 0, 'gray95', 'gray85'))

#最后绘制散点：颜色代表门分类，直接使用 ggplot2 默认颜色；大小表示丰度；实心表示富集 OTUs
p <- p + 
  geom_point(aes(size = abundance, color = phylum, shape = enrich)) +
  scale_size(range = c(1, 5))+
  scale_shape_manual(limits = c('sign', 'no-sign'), values = c(16, 1)) +    
  guides(color = 'none') +
  geom_hline(yintercept = -log10(0.01), color = 'gray', linetype = 2, size = 1)

p

#输出图片至本地
#ggsave('otu.pdf', p, width = 10, height = 5)
#ggsave('otu.png', p, width = 10, height = 5)

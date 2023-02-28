# Objective
> Identify and solve a problem involving dirty, private, and/or siloed data in your domain of interest and expertise. E.g.,
> * **Apply some of the techniques from class to a new setting**
> * Improve over an existing solution
> * An in-depth comparison of different techniques

# Idea

In our project we apply zero-shot entity resolution (ZeroER) to a novel real-world datasource: traffic incident data scraped daily from the MN Department of Safety (DPS) crash website. We then feed a combination of name, vehicle, and incident text descriptions from the scraped MN DPS data into a Google News API wrapper to pull titles of top-k articles that Google returned related to each incident search. We then attempt to de-duplicate the MnDOT structured data without removing distinct entries, and to join to the information from local news articles on cause of the accident. We also will join likely weather conditions at the time of the accident to the MnDOT data. Our project will meet the bolded objective above.

# Introduction
Entity resolution (sometimes called entity matching), the process of matching two disparate data sources or relations without primary key or primary-foreign key associations, is a commonplace need across industries and domains. In the consumer packaged goods (CPG) industry, for example, product data on in-store sales is frequently purchased from outside vendors (such as Nielsen), necessitating a pipeline for efficiently joining this data back to other data (such as marketing spend) available internally. Likewise, in healthcare, there are also a variety of applications: matching tuples of the same individual who signed up for coverage using two different emails or addresses but has the same name and DOB, for example, or matching a doctor’s clinical note describing a procedure to the correct billing code for that procedure. Other industries have similar needs requiring advanced entity resolution techniques beyond rule-based schemes or heuristics.

# Naive solution
State-of-the-art methods like TDMatch show incredible promise for matching and/or de- duplicating datasets at scale, without many labeled examples. The ability to do this greatly reduces the burden on organizations to perform large, expensive labeling projects in order to create data de-duplication pipelines; instead, only observations for which the model has high uncertainty about its predictions need be sent to humans-in-the-loop for manual labeling.

# Why a naive approach is insufficient
However, these existing methods mainly focus on public, general-audience datasets for which an abundance of supplementary metadata (e.g. DBpedia) exists. Certain datasets, like traffic incident datasets, contain data on specific collisions occurring at certain dates and times, and cannot easily be enhanced using public knowledge databases. Moreover, sometimes these datasets contain duplicate entries for the same incident depending on how long it takes to clear the scene; other times, multiple incidents have occurred at the same or similar enough times that they may be mistaken as duplicate entries. Fortunately, zero-shot learning entity resolution methods, such as [ZeroER](https://github.com/chu-data-lab/zeroer), have recently been developed that allow for highly precise and accurate entity matching between multiple such differing datasets.

# Group members
* Nicole Sullivan
* Mohammed Guiga

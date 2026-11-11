---
title: ME/CFS & Long COVID
description: A summary of research related to ME/CFS and Long COVID
created: 2022-12-07
updated: 2026-09-14
hidden: true
---

> Note that this article outdated and may require extensive fact checking to be
> reused. Due to above reason, I've marked this page as hidden and can only be
> accessed with a direct link. Most if not all of the below proposal should
> already be included in <https://arxiv.org/abs/2404.04345> and/or
> <https://www.frontiersin.org/journals/neurology/articles/10.3389/fneur.2025.1691147>.

This post is an introduction to my bachelor's thesis background information,
related work done before writing the final draft.

## Background

The research project I'm in is a joint study between the University of Utah and
the Bateman Horne Center and I am using this project as the foundation of my
bachelor's thesis under
[Dr. Shad Roundy](https://iss.mech.utah.edu/shad-roundy)'s supervision and
co-adviser [Dr. Tucker Hermans](https://robot-learning.cs.utah.edu/thermans).

The purpose of this research project is to find and prove digital bio-marker(s)
that can be used to diagnose and measure the severity of
[myalgic encephalomyelitis/chronic fatigue syndrome](https://www.cdc.gov/me-cfs/about/index.html)
(ME/CFS) and Long COVID.

Before joining this study,Turner Palombo already did his master's thesis titled
"[Development of an Inertial Measurement-Based Assessment of Disease Severity in Chronic Fatigue Syndrome](https://iss.mech.utah.edu/wp-content/uploads/sites/103/2021/06/TurnerPalomboThesis.pdf)"
[1] and a large portion of my work is based on his.

## About ME/CFS Diagnose Method

If you don't know what ME/CFS is, CDC has a pretty good
[overview](https://www.cdc.gov/me-cfs/about/index.html) of it.

Based on
[a research paper published in 2013](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC3560481/)
that discusses how the severity of ME/CFS is measured:

> CFS symptom severity score: The CFS Severity Score was a self-administered,
> recall-biased assessment of overall complaints for the previous 6 month
> period. Fatigue and the 8 minor criteria were scored as none (score = 0),
> trivial (score = 1), mild (score = 2), moderate (score = 3) and severe (score
> = 4). [2]

The method discussed in the paper is still a mainstream method to measure the
severity of ME/CFS, but it is relying on patients' subjective, unreliable
self-reporting, which is not ideal for medical diagnosis.

## About Long COVID and it's Correlation with ME/CFS

If you don't know what Long COVID is,
[this article](https://web.archive.org/web/20220813002017/https://www.cdc.gov/coronavirus/2019-ncov/long-term-effects/index.html?CDC_AA_refVal=https%3A%2F%2Fwww.cdc.gov%2Fcoronavirus%2F2019-ncov%2Flong-term-effects.html)
from CDC is a good overview of it.

In a recent
[post](https://web.archive.org/web/20220811021248/https://covid19.nih.gov/news-and-stories/studying-long-covid-might-help-others-post-viral-fatigue-ailments)
(August 8, 2022) published by the National Institute of Health, they mentioned:

> In 2015, researchers estimated that ME/CFS affected between 900,000 and 2.5
> million people in the United States, most of them undiagnosed. Other symptoms
> include sleeping issues, problems with memory and cognition, and muscle
> soreness. If these symptoms sound familiar, it is because ME/CFS shares
> symptoms in common with long COVID, a group of symptoms some people who have
> had COVID-19 experience for weeks or months after their initial illness.
> Symptoms of long COVID include fatigue, post-exertional malaise, breathing
> problems, and heart palpitations.

Also, in multiple other studies in symptomatology relating with ME/CFS and Long
COVID [3] (keyword: "ME/CFS", "Long COVID", "Post-COVID CFS", "Symptomatology"),
researchers found that the symptoms of ME/CFS and Long COVID are very similar.

Since ME/CFS and Long COVID share multiple similar syndromes, it is reasonable
to assume that the same digital bio-marker(s) can be used to diagnose and
measure the severity of both diseases.

## OI, HUA, UpTime, and Steps/Day

In
[Upright Activity and Exercise Intolerance: Critical Concepts in the Evaluation of Chronic Fatigue](https://batemanhornecenter.org/wp-content/uploads/filebase/education/mecfs/Upright-Activity-and-Exercise-Intolerance-AAEM-Oct-2019.pdf),
and also in
[Clinically accessible tools for documenting the impact of orthostatic intolerance on symptoms and function in ME/CFS](https://content.iospress.com/articles/work/wor203169)
[4], the researchers mentioned Orthostatic Intolerance (OI) is correlated with
the severity of ME/CFS and Long COVID, and patients' HUA can be statistically
quantified with UpTime (but what is UpTime? we define UpTime as the time when
the patient's lower leg, the lower part of the leg from the knee to the ankle,
is in an upright position).

To measure UpTime, we use wearable devices to gather sensor data (accelerometer,
gyroscope) and calculate leg angles using Kalman Filtered data points and
quaternion, then for each calculated angle, we compare it with a threshold angle
(in this case, 39 degrees, see
[Turner's thesis](https://iss.mech.utah.edu/wp-content/uploads/sites/103/2021/06/TurnerPalomboThesis.pdf))
to determine if the leg is in an upright position or not.

```mermaid
flowchart LR
  Raw_Sensor_Data("raw sensor data") --> Filter("filter")
  Filter --> Quaternion("quaternion")
  Quaternion --> Angle("angle")
  Angle --> UpTime("UpTime")
  UpTime --> UpTime_Percentage("UpTime percentage")
```

Since OI refers to the inability to remain upright, with common symptoms such as
lightheadedness[5], and UpTime is measuring patients' HUA, we have high
confidence that patients' severe OI would have less HUA thus lower UpTime
percentage, thus UpTime is a good candidate to be an objective measure of OI
then infers the severity of patients' ME/CFS and Long COVID.

Moreover, since we will already be collecting patients' UpTime data through raw
sensor data, why not explore other potential digital bio-markers that can be
used to diagnose and measure the severity of ME/CFS and Long COVID? Since
people's daily activity level is somewhat related to the steps they take,
Steps/Day is used as a companion digital bio-marker to UpTime.

## We Need Solid Proofs

Even though we're confident UpTime can be a valid digital-biomarker to measure
severity of ME/CFS and Long COVID, we still need to prove that through data and
evidence.

In an initial study undertaken by Turner Palombo showed a correlation between
UpTime and ME/CFS disease severity. However, this result is preliminary as the
study that showed the correlation only had 15 subjects. Therefore, we are
collaborating with the Bateman Horne Center on a larger study (the ongoing
study) with 75 participants which has a ME/CFS cohort, a Long COVID cohort, and
a healthy control cohort.

The first objective of this ongoing study will be to verify the finding from the
preliminary study. Second we will evaluate UpTime and Steps/Day as measures of
disease severity for ME/CFS and Long COVID. Finally we will explore other
potential biomarkers.

## IMU: From Shimmer to MMS

Related links: [IMU](https://en.wikipedia.org/wiki/Inertial_measurement_unit),
[Shimmer](https://shimmersensing.com/),
[MMS](https://mbientlab.com/metamotions/).

I mentioned we used wearable devices to gather accelerometer and gyroscope data,
and those data points are coming from IMUs (Inertial Measurement Units).

In the original study, Turner analyzed sensor data generated by
[Shimmer](https://shimmersensing.com/), when I got my hand on the project, we
switched to [MMS](https://mbientlab.com/metamotions/), the sensor data format
generated by the above two sensors is the same.

The main reason for the switch is due to battery life and participants'
comfortness: Shimmer IMUs are big but they only last around 3 days, we found it
not ideal for mid-term monitoring (which usually lasts about 1 week), so we
switched to MMS IMUs (lightweight, water-proof with our band), which can last up
to 2 weeks with our data collection parameters.

The nice thing about MMS is that they provide very comprehensive APIs for almost
all mainstream programming languages and user platforms, I extended their C++
and Python library to allow us to have concurrent serial data transfer from the
sensor to Raspberry Pi (or any other Linux-based system).

For each study participant, they will wear the MMS device on one of their lower
leg for a week, and send the device back to BHC for data collection through a
terminal interface on Raspberry Pi. In addition to wearing the IMUs for a week,
participants in the study completed questionnaires including RAND36, OISA, and
OIDAS.

## Data Flow

All code used for the study will be available as artifacts after our study
result is published, and overall workflow is on this simple data flow diagram.

```txt
|----------------------------|  issue download command  |--------|
| Terminal (deployed at BHC) | -----------------------> | AWS S3 |
|----------------------------|                          |--------|
                                                            |
                                                |-> watcher |
                                                |           |
                                                |<----------|
                                                  no change |
                                                            |
                                            change detected |
                                                            |
                                |--------------|            |
                         |----- | preprocessor | <-----------
                         |      |--------------|
                         |
                         |--------------------> download
                                              | unzip
                                              | trim
                                              | error check
                                              | uptime
                                              | steps
                                              | notify
                  investigator <--------------|
                                processed data
```

After study participants send back the MMS device, the data will be downloaded
from the device on a Raspberry Pi, compressed, then uploaded to AWS S3. A
"watcher" (a cron-job running on local server keeps checking AWS S3 bucket
directory) will be triggered to check if there is any new data, if there is, the
preprocessor will be triggered to process the data, and finally the processed
data will be sent to the investigator.

For data security, the raw sensor data transported from Terminal and AWS S3
(Python Boto3), from AWS S3 to the processing server (Python Boto3) is encrypted
with TLS, and data backed up on AWS S3 have AWS-managed encryption with
encryption key rotation. Other than that, all data is transported within a local
network formed between [Tailscale](https://tailscale.com/) nodes.

## UpTime, Steps/Day and Other Digital Bio-Markers

Since we collect both accelerometer and gyroscope data at 25Hz for a week for
each study participant (~2.5GB per recording session), it would be a waste just
to use such comprehensive data to calculate UpTime. So we added Steps/Day as
another digital bio-marker, not quite proven yet, but it is a good candidate
(ME/CFS or Long COVID -> possible Orthostatic Intolerance -> not as active ->
low step count).

UpTime and Steps/Day are the two digital bio-markers that are being analyzed
now. Methods used are described in
[Turner's thesis](https://iss.mech.utah.edu/wp-content/uploads/sites/103/2021/06/TurnerPalomboThesis.pdf).
I was able to replicate Turner's results using the same methods in Python (his
original code is in MATLAB).

Other than UpTime and Steps/Day, we also have standardized survey data for each
participant (RAND36, OISA, OIDAS, etc.), we are also working on a way
(linear/quadratic regression, unsupervised ML, etc.) to combine those data with
UpTime and Steps/Day to get a more accurate diagnosis.

## Roadmap

**2021-08 ~ 2022-07**

- MMS and Raspberry Pi setup
- MMS hardware interface with Raspberry Pi
- Custom library for our specific use case
- Pre-processing pipeline
- UpTime and Steps/Day calculation

**2022-08 ~ 2022-12**

- Does UpTime predicts the existence of ME/CFS?
- Does UpTime predicts the existence of Long COVID?
- Does Steps/Day predicts the existence of ME/CFS?
- Does Steps/Day predicts the existence of Long COVID?
- Check standardized survey data's correlation with UpTime and Steps/Day
  (RAND36, OISA, OIDAS)

**2022-12 ~ 2022-05**

- Explore multi-regression models
- Explore other digital bio-markers
- Explore ML approach

After gathering terabytes worth of sensor data, we used the raw data to
determine UpTime and Steps/Day, then evaluate UpTime and Steps/Day and linear
combination of the two as a predictor for ME/CFS disease severity. The final
step of our analysis will seek to find a more accurate predictor of ME/CFS
disease severity using the data in these questionnaires. We will pursue
multi-linear and polynomial regression and an unsupervised machine learning
approach to find a classifier for ME/CFS disease severity.

## References

[1] Palombo T, Vernon S, Roundy S. Development of an Inertial Measurement-Based
Assessment of Disease Severity in Chronic Fatigue Syndrome. Master's Thesis, The
University of Utah Department of Mechanical Engineering, August 2020.

[2] Baraniuk JN, Adewuyi O, Merck SJ, Ali M, Ravindran MK, Timbol CR, Rayhan R,
Zheng Y, Le U, Esteitie R, Petrie KN. A Chronic Fatigue Syndrome (CFS) severity
score based on case designation criteria. Am J Transl Res. 2013;5(1):53-68. Epub
2013 Jan 21. PMID: 23390566; PMCID: PMC3560481.

[3] Wong TL, Weitzer DJ. Long COVID and Myalgic Encephalomyelitis/Chronic
Fatigue Syndrome (ME/CFS)-A Systemic Review and Comparison of Clinical
Presentation and Symptomatology. Medicina (Kaunas). 2021 Apr 26;57(5):418. doi:
10.3390/medicina57050418. PMID: 33925784; PMCID: PMC8145228.

[4] Lee, Jihyun et al. 'Clinically Accessible Tools for Documenting the Impact
of Orthostatic Intolerance on Symptoms and Function in ME/CFS'. 1 Jan. 2020 :
257 - 263.

[5] Stewart JM. Common syndromes of orthostatic intolerance. Pediatrics. 2013
May;131(5):968-80. doi: 10.1542/peds.2012-2610. Epub 2013 Apr 8. PMID: 23569093;
PMCID: PMC3639459.

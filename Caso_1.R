setwd("/home/gustavo/Projeto de Dados/Análise_R/AP2/Caso_1")
getwd()

install_github('NickCH-K/vtable')
install.packages("plm")
install.packages("stargazer")

library(devtools)
library(vtable)
library(readxl)
library(tidyverse)
library(dplyr)
library(foreign)
library(plm)
library(stargazer)
library(MatchIt)

caso1 <- read_excel("/home/gustavo/Projeto de Dados/Análise_R/AP2/Caso_1/Caso_1.xlsx")
View(caso1)

############################### Letra A ########################################
# Indicação de desenho adequado para a identificação do efeito da PP

## Efeito de Politica por educação
ep = lm(educ ~ educ2004, data = caso1)
summary(ep)

## Variável ficticia do efeito PP por educação
vf = lm(educ ~ educ2004 + factor(pp) + factor(sexo), data = caso1)
summary(vf)

## Variável ficticia do efeito PP por Pop em renda
vf_pop = lm(pop ~ renda + factor(pp) + factor(sexo), data = caso1)
summary(vf_pop)

## dentro do estimator de sexo para pp
dentro_estimador1 = plm(educ ~ educ2004 + factor(sexo), index = "pp", model = "within", data = caso1) 
summary(dentro_estimador1)

## dentro do estimator de pp para sexo com calculo de renda 
dentro_estimador2 = plm(renda ~ educ + educ2004 + factor(pp), index = "sexo", model = "within", data = caso1)
summary(dentro_estimador2)

## dentro do estimator de pp para sexo
dentro_estimador3 = plm(educ ~ educ2004 + factor(pp), index = "sexo", model = "within", data = caso1) 
summary(dentro_estimador3)

## dentro do estimator de sexo para pp com calculo de renda 
dentro_estimador4 = plm(renda ~ educ + educ2004 + factor(sexo), index = "pp", model = "within", data = caso1)
summary(dentro_estimador4)

######################### Letra B ##############################################

## Tabela de Balançeamento por estimação da educação e pop (Comparação entre pp e sexo)

################################### PP ########################################

#################### Pop e Renda para o PP ######################
caso1 %>% 
  select(-pop, -renda) %>% 
  sumtable(group = 'pp', group.test = TRUE)

#################### Educ e educ2004 para o PP ##################
caso1 %>% 
  select(-educ, -educ2004) %>% 
  sumtable(group = 'pp', group.test = TRUE)

################### Pop e Renda para o Sexo ###################### 
caso1 %>% 
  select(-pop, -renda) %>% 
  sumtable(group = 'sexo', group.test = TRUE) 

################### Educ e Educ2004 ############################## 
caso1 %>% 
  select(-educ, -educ2004) %>% 
  sumtable(group = 'sexo', group.test = TRUE)

################################# Letra C #####################################

### Matching, apresentar a tabela de balanceamento antes e depois do pareamento

## Indice de desempenho dos sexos por educação 

caso1 %>% 
  group_by(sexo) %>% 
  summarise(educ2004 = n(),
            media_educacao = mean(educ), 
            std_error = sd(educ) / sqrt(educ2004))

## Calculo da renda pela media na educação por desvio padrão na educação 2004
caso1 %>% 
  group_by(sexo) %>% 
  mutate(teste = (renda - mean(educ)) / sd(educ2004))

## Propensity Score 

## Frequencia de Histograma para media o caso da educação
caso1 <- caso1 %>% mutate(educ = educ / 1000) 
hist(caso1$educ)

## Selecionando os sexo e pp por educ2004
caso_educ <- caso1 %>% 
  select(sexo, pp, educ2004) %>% 
  na.omit()

## Verificação de dados 
dim(caso1)
dim(caso_educ)

# Algoritmo de Matchit
mod_match <- matchit(sexo ~ pp + educ + educ2004 + renda, method = "nearest", data = caso1)
summary(mod_match)

## Um novo banco de dados só com os pareados
dat_m <- match.data(mod_match)
head(dat_m) 
dim(dat_m)

## Caso Pareado de Teste 
with(dat_m, t.test(renda ~ sexo))
with(dat_m, t.test(educ ~ sexo))
with(dat_m, t.test(educ2004 ~ sexo))

with(dat_m, t.test(renda ~ pp))
with(dat_m, t.test(educ ~ pp))
with(dat_m, t.test(educ2004 ~ pp))

## Regressão Linear 
rl_educ_sexo <- lm(educ ~ sexo, data = dat_m)
summary(rl_educ_sexo)

rl_geral <- lm(renda ~ sexo + educ + I(educ2004 / 10^3), data = dat_m)
summary(rl_geral)

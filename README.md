# app_financeiro_pessoal

Regras de negócios estabelecidas:
📆 1. Estrutura do Mês Financeiro

    RN01: O mês financeiro do usuário inicia no dia 20 de cada mês.

    RN02: Todas as movimentações (receitas e despesas) devem ser consideradas dentro do intervalo de 20 do mês anterior até 19 do mês atual.

💰 2. Receitas

    RN03: As receitas devem ser cadastradas com:

        Descrição

        Valor

        Data de recebimento

        Categoria (ex: Salário, Benefício, Aluguel)

    RN04: As receitas serão somadas para compor o orçamento total disponível no mês.

    RN05: Receitas podem ser recorrentes ou pontuais.

💸 3. Despesas
3.1 Despesas Fixas (Débito em Conta ou Cartão)

    RN06: As despesas devem ser cadastradas com:

        Descrição

        Valor

        Forma de pagamento (Cartão, Débito, Pix, Dinheiro, etc.)

        Categoria (ex: Moradia, Educação, Transporte, Lazer, Saúde, etc.)

        Recorrência (Mensal, Única, Parcelada)

        Data de vencimento ou pagamento

    RN07: Despesas recorrentes devem ser lançadas automaticamente nos meses seguintes.

    RN08: Despesas parceladas devem ser registradas com valor total e número de parcelas; o sistema calculará o valor mensal e exibirá as parcelas futuras.

    RN09: Gastos em cartão de crédito devem ser associados à fatura do mês financeiro correspondente, com controle por fechamento de fatura.

🧾 4. Categorias e Orçamento

    RN10: O usuário poderá definir categorias de despesas (ex: Alimentação, Moradia, Educação, Lazer, etc.).

    RN11: Cada categoria poderá ter um orçamento mensal definido pelo usuário.

    RN12: À medida que despesas são lançadas, o sistema deve:

        Abater o valor da categoria correspondente.

        Mostrar quanto ainda resta no orçamento da categoria.

    RN13: O sistema também deve mostrar o total já gasto e restante do orçamento geral do mês.

💳 5. Cartão de Crédito

    RN14: Compras feitas no cartão de crédito devem ser vinculadas à fatura do mês (de acordo com a data de fechamento configurada).

    RN15: Parcelamentos devem gerar múltiplas entradas nas faturas dos meses futuros.

    RN16: Gastos no cartão também devem ser categorizados e afetar os limites de orçamento por categoria.

🔄 6. Reembolsos (Para Fase 2)

    RN17: O sistema permitirá marcar despesas com reembolso parcial ou total.

    RN18: Reembolsos não serão considerados no cálculo do orçamento até serem efetivamente recebidos.

📊 7. Relatórios e Acompanhamento

    RN19: O sistema deve apresentar:

        Gasto por categoria (gráfico e lista)

        Evolução mensal dos gastos

        Comparativo entre orçamento e gasto real

        Saldo restante do mês

    RN20: Alertas serão exibidos quando uma categoria estiver perto ou ultrapassar o orçamento.

🧠 8. Outras Considerações

    RN21: Todas as transações devem conter data, valor, forma de pagamento, e categoria.

    RN22: O usuário poderá visualizar o mês atual, meses anteriores e planejamento de meses futuros (principalmente por conta de parcelamentos).

    RN23: O sistema deve ser multi-conta (ex: contas bancárias separadas ou múltiplos cartões), mas isso pode ser considerado numa fase futura.

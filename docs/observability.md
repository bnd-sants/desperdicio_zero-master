# Observabilidade e Alertas para `advisors_reports`

Este guia mostra como transformar os eventos enviados pelo `TelemetryService` em dashboards e alertas centralizados dentro do Supabase.

## 1. Dashboard SQL no Supabase

1. Abra o Supabase Dashboard ➜ `SQL Editor`.
2. Crie uma view que normalize os campos mais importantes:

```sql
create view if not exists public.vw_advisors_reports as
select
  id,
  created_at,
  details->>'severity' as severity,
  details->>'message' as message,
  details->>'source'  as source,
  details->>'category' as category,
  details->>'stackTrace' as stacktrace
from public.advisors_reports
order by created_at desc;
```

3. Depois de criada a view, use o recurso **Charts** do Supabase (ou qualquer BI compatível com Postgres) para montar gráficos:
   - Quantidade de eventos por severidade.
   - Erros por tela/feature (`details->>'source'`).
   - Tendência diária de falhas críticas.

> Dica: utilize filtros em `severity`/`category` para gerar dashboards separados (ex.: `profile`, `runtime`).

## 2. Alerts via Supabase Edge Function

Para enviar alertas em tempo real (Slack, Discord, Webhook próprio), crie uma Edge Function que é chamada sempre que um registro novo for inserido.

### 2.1 Estrutura básica da função

Crie `supabase/functions/advisors-webhook/index.ts`:

```ts
import { serve } from "https://deno.land/std@0.208.0/http/server.ts";

serve(async (req) => {
  const { type, record } = await req.json();

  if (type !== "INSERT" || !record) {
    return new Response("noop");
  }

  const webhookUrl = Deno.env.get("OBS_WEBHOOK_URL");
  if (!webhookUrl) {
    console.error("Webhook URL não configurada");
    return new Response("missing webhook", { status: 500 });
  }

  const payload = {
    text: `:rotating_light: ${record.details?.severity?.toUpperCase()} - ${record.details?.message}\nCategoria: ${record.details?.category}\nFonte: ${record.details?.source}\nTimestamp: ${record.created_at}`,
  };

  await fetch(webhookUrl, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(payload),
  });

  return new Response("ok");
});
```

### 2.2 Variáveis de ambiente

```bash
supabase secrets set OBS_WEBHOOK_URL="https://hooks.slack.com/services/..."
```

### 2.3 Trigger para a função

Crie uma função SQL que chame a Edge Function sempre que um insert ocorrer em `advisors_reports`:

```sql
create or replace function public.notify_advisors_webhook()
returns trigger as $$
begin
  perform
    net.http_post(
      url := 'https://<project-ref>.functions.supabase.co/advisors-webhook',
      headers := jsonb_build_object('Authorization', 'Bearer ' || current_setting('app.settings.service_role_key')),
      body := jsonb_build_object('type', 'INSERT', 'record', row_to_json(new))
    );
  return new;
end;
$$ language plpgsql security definer;

create trigger trg_advisors_webhook
  after insert on public.advisors_reports
  for each row execute procedure public.notify_advisors_webhook();
```

> Substitua `<project-ref>` e garanta que o service role key esteja disponível no parâmetro `app.settings.service_role_key` (adicione via `ALTER DATABASE SET`).

## 3. Exportação periódica

Caso queira exportar históricos para outra ferramenta (BigQuery, S3, etc.), utilize **Cron Functions** do Supabase:

1. Criar função Edge que lê registros novos no intervalo e envia para o destino.
2. Usar `supabase functions deploy` e configurar `supabase cron schedule` para rodar a cada X minutos.
3. Persistir `last_exported_at` em uma tabela auxiliar para evitar duplicidade.

## 4. Próximos passos sugeridos

- Adicionar filtros no `TelemetryService` para marcar eventos com `category` (ex.: `profile`, `runtime`, `network`), facilitando dashboards.
- Criar testes automatizados que verifiquem o envio de telemetria (mockando o insert no Supabase) para garantir que eventos críticos não sejam perdidos.
- Se necessário, integrar com ferramentas externas como Logflare ou Sentry usando o mesmo modelo de Edge Function.

## 5. Novos eventos da V1.4

- `barcode_scan_success`: leitura de codigo de barras com preenchimento automatico.
- `barcode_scan_not_found`: codigo lido sem match no Open Food Facts.
- `offline_products_loaded`: fallback para cache local de produtos quando API falha.
- `recipe_rank_applied`: filtros de score por despensa aplicados em receitas.
- `smart_tip_scheduled`: alerta contextual inteligente agendado.
- `monthly_dashboard_viewed`: dashboard mensal de desperdicio exibido.

Consulta rapida:

```sql
select
  details->>'message' as event_name,
  count(*) as total
from public.advisors_reports
where details->>'message' in (
  'barcode_scan_success',
  'barcode_scan_not_found',
  'offline_products_loaded',
  'recipe_rank_applied',
  'smart_tip_scheduled',
  'monthly_dashboard_viewed'
)
group by event_name
order by total desc;
```

-- Create private storage bucket for gem audio files
insert into storage.buckets (id, name, public)
values ('gems-audio', 'gems-audio', false);

-- Storage policies: users can manage files in their own folder (userId/*)
create policy "Users upload own audio"
  on storage.objects for insert
  with check (
    bucket_id = 'gems-audio'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

create policy "Users read own audio"
  on storage.objects for select
  using (
    bucket_id = 'gems-audio'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

create policy "Users delete own audio"
  on storage.objects for delete
  using (
    bucket_id = 'gems-audio'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

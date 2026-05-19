# Generated manually

from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ('startScan', '0002_auto_20240911_0145'),
    ]

    operations = [
        # Remove GPTVulnerabilityReport model
        migrations.DeleteModel(
            name='GPTVulnerabilityReport',
        ),

        # Remove Waf model
        migrations.DeleteModel(
            name='Waf',
        ),

        # Remove waf field from Subdomain
        migrations.RemoveField(
            model_name='subdomain',
            name='waf',
        ),

        # Remove hackerone_report_id from Vulnerability
        migrations.RemoveField(
            model_name='vulnerability',
            name='hackerone_report_id',
        ),

        # Remove is_gpt_used from Vulnerability
        migrations.RemoveField(
            model_name='vulnerability',
            name='is_gpt_used',
        ),

        # Remove used_gf_patterns from ScanHistory
        migrations.RemoveField(
            model_name='scanhistory',
            name='used_gf_patterns',
        ),

        # Add Fingerprint model
        migrations.CreateModel(
            name='Fingerprint',
            fields=[
                ('id', models.AutoField(primary_key=True, serialize=False)),
                ('name', models.CharField(max_length=500)),
                ('version', models.CharField(blank=True, max_length=200, null=True)),
                ('source', models.CharField(help_text='Tool that detected this fingerprint (whatweb, cmseek)', max_length=50)),
                ('extra_info', models.TextField(blank=True, help_text='Additional fingerprint details in JSON format', null=True)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('scan_history', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.CASCADE, to='startScan.scanhistory')),
                ('subdomain', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.CASCADE, related_name='fingerprints', to='startScan.subdomain')),
            ],
            options={
                'unique_together': {('subdomain', 'name', 'source')},
            },
        ),
    ]

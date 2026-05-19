# Generated manually

from django.db import migrations


class Migration(migrations.Migration):

    dependencies = [
        ('dashboard', '0002_chaosapikey_hackeroneapikey_inappnotification_userpreferences'),
    ]

    operations = [
        # Remove OpenAiAPIKey model
        migrations.DeleteModel(
            name='OpenAiAPIKey',
        ),

        # Remove OllamaSettings model
        migrations.DeleteModel(
            name='OllamaSettings',
        ),

        # Remove NetlasAPIKey model
        migrations.DeleteModel(
            name='NetlasAPIKey',
        ),

        # Remove ChaosAPIKey model
        migrations.DeleteModel(
            name='ChaosAPIKey',
        ),

        # Remove HackerOneAPIKey model
        migrations.DeleteModel(
            name='HackerOneAPIKey',
        ),

        # Remove UserPreferences model
        migrations.DeleteModel(
            name='UserPreferences',
        ),
    ]

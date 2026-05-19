# Generated manually

from django.db import migrations


class Migration(migrations.Migration):

    dependencies = [
        ('scanEngine', '0002_hackerone_send_report'),
    ]

    operations = [
        # Remove Hackerone model
        migrations.DeleteModel(
            name='Hackerone',
        ),
    ]

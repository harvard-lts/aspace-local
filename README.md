# aspace-local
containing that which we need for plugins/local in archivesspace

Make sure you read the NOTES file for other changes needed to maintain the Harvard Archivesspace environment.

We began this repository for the installation of ArchivesSpace v2.5.0

## Installation:

1. Read the [notes file](NOTES.md) for other changes that are needed.
2. Download and unzip the latest release under `archivesspace/plugins`, then rename to `local`
3. Use the Harvard-enhanced ead-to-pdf stylesheet:

```bash
mv archivesspace/stylesheets/as-ead-pdf.xsl archivesspace/stylesheets/as-ead-pdf.xsl_orig
mv archivesspace/plugins/local/as-ead-pdf.xsl archivesspace/stylesheets/
```

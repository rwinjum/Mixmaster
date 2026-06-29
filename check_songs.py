import csv

corrections = {
    'Comfortably Numb': '1979-11-30',
    'More Than This': '1982-05-01', 
    'Everybody Wants You': '1982-07-23',
    'Crown of Thorns': '1989-03-20',
    'Dancing Days': '1971-11-08',
    'Who Are You': '1978-12-18',
    'Acquiesce': '1996-10-07',
    'Boulevard of Broken Dreams': '2004-11-01',
    'Losing My Religion': '1991-01-01',
    'All Your Lies': '1988-06-09',
    'Mood for Trouble': '1988-06-09',
    'Flower': '1988-06-09',
    'Hands All Over': '1989-01-24',
    'The Underdog': '2007-04-10',
    'Drown': '1995-10-23',
    'American Girl': '1976-09-14',
    'Ocean Size': '1989-09-07',
    'We Walk': '1985-01-01',
    'Harborcoat': '1983-01-01',
    'Southbound': '1973-08-15',
    'Hold Me': '1995-06-05',
    'Marie': '1961-08-08',
    'Invisible Sun': '2019-09-20',
    'As Alive': '2025-07-17',
    'Everywhere': '2016-04-08',
    'Wait for Me': '2012-09-18'
}

found = 0
songs_in_csv = []
with open('BW26-withallcorrectMETA.csv', 'r', encoding='utf-8') as f:
    reader = csv.DictReader(f)
    for row in reader:
        track = row['Track Name'].lower() if row['Track Name'] else ''
        for song in corrections.keys():
            if song.lower() in track:
                found += 1
                songs_in_csv.append(song)
                break

print(f'Found {found}/{len(corrections)} correction songs in CSV')

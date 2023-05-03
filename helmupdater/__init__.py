import subprocess
import json
import os

from semver import VersionInfo
import chevron
import requests
import typer
import yaml

app = typer.Typer()

CHART_TEMPLATE = '''{
  repo = "{{ repo }}";
  chart = "{{ chart }}";
  version = "{{ version }}";
  chartHash = "{{ hash }}";{{#bogus_version}}
  bogusVersion = true;{{/bogus_version}}
}
'''

def build_chart(repo_name: str, chart_name: str, check=False):
  return subprocess.run([
    'nix',
    'build',
    f'.#chartsDerivations.x86_64-linux.{repo_name}.{chart_name}'
  ], capture_output=True, text=True, check=check)

def get_hash(repo_name: str, chart_name: str) -> str:
  cp = build_chart(repo_name, chart_name)
  for l in cp.stderr.split('\n'):
    l = l.strip()
    if not l.startswith('got:'):
      continue
    l = l[4:]
    return l.strip()
  return None

def get_charts():
  return json.loads(subprocess.check_output(['nix', 'eval', '.#chartsMetadata', '--json']))

def update_one_chart(repo_name: str, chart_name: str, local_chart, commit: bool):
  repo_url = local_chart['repo']
  if repo_url[-1] != '/':
    repo_url += '/'

  index_req = requests.get(f'{repo_url}index.yaml')
  index_req.encoding = 'utf8'
  all_charts = yaml.safe_load(index_req.text)
  remote_chart = all_charts['entries'][chart_name]
  bogus_version = local_chart.get('bogusVersion', False)
  raw_version = local_chart['version']
  bogus_version_fixed = False
  if bogus_version and raw_version.startswith('v'):
    raw_version = raw_version[1:]
    bogus_version_fixed = True
  my_version = VersionInfo.parse(raw_version)
  remote_version = '0.0.0'

  for chart in remote_chart[::-1]:
    version_str = chart['version']
    if bogus_version and version_str.startswith('v'):
      version_str = version_str[1:]
      bogus_version_fixed = True
    if len(version_str.split('-')) != 1:
      continue
    version = VersionInfo.parse(version_str)
    if version > remote_version:
      remote_version = version

  if remote_version <= my_version:
    return
  
  if bogus_version_fixed:
    my_version = 'v' + str(my_version)
    remote_version = 'v' + str(remote_version)
  
  print(f'updating {my_version} -> {remote_version}')
  
  chart_path = os.path.join(os.curdir, 'charts', repo_name, chart_name, 'default.nix')
  
  with open(chart_path, 'w') as f:
    f.write(chevron.render(
      CHART_TEMPLATE,
      data=dict(
        repo=repo_url,
        chart=chart_name,
        version=str(remote_version),
        hash='sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=',
        bogus_version=bogus_version,
      )))
  
  correct_hash = get_hash(repo_name, chart_name)

  if not correct_hash:
    raise RuntimeError('failed to get the correct hash') 
  
  with open(chart_path, 'w') as f:
    f.write(chevron.render(
      CHART_TEMPLATE,
      data=dict(
        repo=repo_url,
        chart=chart_name,
        version=str(remote_version),
        hash=correct_hash,
        bogus_version=bogus_version,
      )))
  
  if commit:
    subprocess.run(['git', 'add', chart_path], check=True)
    subprocess.run(['git', 'commit', '-m', f'{repo_name}/{chart_name}: update to {remote_version}'], check=True)

@app.command()
def update(name: str, commit: bool = typer.Option(False), rebuild: bool = typer.Option(False)):
  repo_name, chart_name = name.split('/')
  charts = get_charts()
  local_chart = charts[repo_name][chart_name]

  update_one_chart(repo_name, chart_name, local_chart, commit)
  if rebuild:
    build_chart(repo_name, chart_name, check=True)

@app.command()
def update_all(commit: bool = typer.Option(False), rebuild: bool = typer.Option(False)):
  charts = get_charts()
  for repo_name, charts in charts.items():
    for chart_name, local_chart in charts.items():
      print(f'checking {repo_name}/{chart_name}')
      try:
        update_one_chart(repo_name, chart_name, local_chart, commit)
        if rebuild:
          build_chart(repo_name, chart_name, check=True)
      except RuntimeError as e:
        print(f'failed: {e}')

@app.command()
def init(repo_url: str, name: str, commit: bool = typer.Option(False), bogus_version: bool = typer.Option(False)):
  repo_name, chart_name = name.split('/')
  charts = get_charts()
  if charts.get(repo_name, {}).get(chart_name, None):
    print('chart already exists')
    exit(1)

  repo_dir = os.path.join(os.curdir, 'charts', repo_name)
  if not os.path.exists(repo_dir):
    os.mkdir(repo_dir)

  chart_dir = os.path.join(repo_dir, chart_name)
  os.mkdir(chart_dir)

  chart_path = os.path.join(chart_dir, 'default.nix')
  with open(chart_path, 'w') as f:
    f.write(chevron.render(
      CHART_TEMPLATE,
      data=dict(
        repo=repo_url,
        chart=chart_name,
        version='0.0.0',
        hash='sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=',
        bogus_version=bogus_version,
      )))
  
  subprocess.run(['git', 'add', chart_path], check=True)
  charts = get_charts()
  local_chart = charts[repo_name][chart_name]
  update_one_chart(repo_name, chart_name, local_chart, commit=False)

  charts = get_charts()
  local_chart = charts[repo_name][chart_name]
  subprocess.run(['git', 'add', chart_path], check=True)

  if commit:
    subprocess.run(['git', 'commit', '-m', f'{repo_name}/{chart_name}: init at {local_chart["version"]}'], check=True)


if __name__ == "__main__":
    app()
